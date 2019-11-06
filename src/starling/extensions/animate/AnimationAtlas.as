package starling.extensions.animate
{
    import flash.utils.Dictionary;

    import starling.display.Image;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    /** An AnimationAtlas stores the data of all the animations found in one set of files
     *  created by Adobe Animate's "export texture atlas" feature.
     *
     *  <p>Just like a TextureAtlas references a list of textures, an AnimationAtlas references
     *  a list of animations. </p>
     */
    public class AnimationAtlas
    {
        public static const ASSET_TYPE:String = "animationAtlas";

        private var _atlas:TextureAtlas;
        private var _symbolData:Dictionary;
        private var _symbolPool:Dictionary;
        private var _imagePool:Array;
        private var _frameRate:Number;
        private var _defaultSymbolName:String;

        private static const STD_MATRIX3D_DATA:Object = {
            "m00": 1, "m01": 0, "m02": 0, "m03": 0,
            "m10": 0, "m11": 1, "m12": 0, "m13": 0,
            "m20": 0, "m21": 0, "m22": 1, "m23": 0,
            "m30": 0, "m31": 0, "m32": 0, "m33": 1
        };

        public function AnimationAtlas(data:Object, atlas:TextureAtlas)
        {
            if (data  == null) throw new ArgumentError("data must not be null");
            if (atlas == null) throw new ArgumentError("atlas must not be null");

            data = normalizeJsonKeys(data);
            parseData(data);

            _atlas = atlas;
            _symbolPool = new Dictionary();
            _imagePool = [];
        }

        /** Indicates if the atlas contains an animation with the given name. */
        public function hasAnimation(name:String):Boolean
        {
            return hasSymbol(name);
        }

        /** Creates a new instance of the animation with the given name. If you don't provide
         *  a name, the default symbol name will be used (i.e. the symbol's main timeline). */
        public function createAnimation(name:String=null):Animation
        {
            name ||= _defaultSymbolName;
            if (!hasSymbol(name)) throw new ArgumentError("Animation not found: " + name);
            return new Animation(name, this);
        }

        /** Returns a list of all the animation names contained in this atlas. */
        public function getAnimationNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            out ||= new Vector.<String>();

            for (var name:String in _symbolData)
                if (name != Symbol.BITMAP_SYMBOL_NAME && name.indexOf(prefix) == 0)
                    out[out.length] = name;

            out.sort(Array.CASEINSENSITIVE);
            return out;
        }

        // pooling

        internal function getTexture(name:String):Texture
        {
            return _atlas.getTexture(name);
        }

        internal function getImage(texture:Texture):Image
        {
            if (_imagePool.length == 0) return new Image(texture);
            else
            {
                var image:Image = _imagePool.pop() as Image;
                image.texture = texture;
                image.readjustSize();
                return image;
            }
        }

        internal function putImage(image:Image):void
        {
            _imagePool[_imagePool.length] = image;
        }

        internal function hasSymbol(name:String):Boolean
        {
            return name in _symbolData;
        }

        internal function getSymbol(name:String):Symbol
        {
            var pool:Array = getSymbolPool(name);
            if (pool.length == 0) return new Symbol(getSymbolData(name), this);
            else return pool.pop();
        }

        internal function putSymbol(symbol:Symbol):void
        {
            symbol.reset();
            var pool:Array = getSymbolPool(symbol.symbolName);
            pool[pool.length] = symbol;
            symbol.currentFrame = 0;
        }

        internal function getSymbolData(name:String):Object
        {
            return _symbolData[name];
        }

        // helpers

        private function parseData(data:Object):void
        {
            var metaData:Object = data.metadata;

            if (metaData && metaData.frameRate > 0)
                _frameRate = int(metaData.frameRate);
            else
                _frameRate = 24;

            _symbolData = new Dictionary();

            // the actual symbol dictionary
            for each (var symbolData:Object in data.symbolDictionary.symbols)
                _symbolData[symbolData.symbolName] = preprocessSymbolData(symbolData);

            // the main animation
            var defaultSymbolData:Object = preprocessSymbolData(data.animation);
            _defaultSymbolName = defaultSymbolData.symbolName;
            _symbolData[_defaultSymbolName] = defaultSymbolData;

            // a purely internal symbol for bitmaps - simplifies their handling
            _symbolData[Symbol.BITMAP_SYMBOL_NAME] = {
                symbolName: Symbol.BITMAP_SYMBOL_NAME,
                timeline: { layers: [] }
            };
        }

        private static function preprocessSymbolData(symbolData:Object):Object
        {
            var timeLineData:Object = symbolData.timeline;
            var layerDates:Array = timeLineData.layers;

            // In Animate CC, layers are sorted front to back.
            // In Starling, it's the other way round - so we simply reverse the layer data.

            if (!timeLineData.sortedForRender)
            {
                timeLineData.sortedForRender = true;
                layerDates.reverse();
            }

            // We replace all "ATLAS_SPRITE_instance" elements with symbols of the same contents.
            // That way, we are always only dealing with symbols.

            var numLayers:int = layerDates.length;

            for (var l:int=0; l<numLayers; ++l)
            {
                var layerData:Object = layerDates[l];
                var frames:Array = layerData.frames as Array;
                var numFrames:int = frames.length;

                for (var f:int=0; f<numFrames; ++f)
                {
                    var elements:Array = frames[f].elements as Array;
                    var numElements:int = elements.length;

                    for (var e:int=0; e<numElements; ++e)
                    {
                        var element:Object = elements[e];

                        if ("atlasSpriteInstance" in element)
                        {
                            element = elements[e] = {
                                symbolInstance: {
                                    symbolName: Symbol.BITMAP_SYMBOL_NAME,
                                    instanceName: "InstName",
                                    bitmap: element.atlasSpriteInstance,
                                    symbolType: SymbolType.GRAPHIC,
                                    firstFrame: 0,
                                    loop: LoopMode.LOOP,
                                    transformationPoint: { x: 0, y: 0 },
                                    matrix3D: STD_MATRIX3D_DATA
                                }
                            }
                        }

                        // not needed - remove decomposed matrix to save some memory
                        if ("decomposedMatrix" in element.symbolInstance)
                            delete element.symbolInstance.decomposedMatrix;
                    }
                }
            }

            return symbolData;
        }

        private function getSymbolPool(name:String):Array
        {
            var pool:Array = _symbolPool[name];
            if (pool == null) pool = _symbolPool[name] = [];
            return pool;
        }

        // properties

        public function get frameRate():Number { return _frameRate; }
        public function set frameRate(value:Number):void { _frameRate = value; }

        // data normalization

        private static function normalizeJsonKeys(data:Object):Object
        {
            if (data is String || data is Number || data is int) return data;
            else if (data is Array)
            {
                var array:Array = [];
                var arrayLength:uint = data.length;
                for (var i:int=0; i<arrayLength; ++i)
                    array[i] = normalizeJsonKeys(data[i]);
                return array;
            }
            else
            {
                var out:Object = {};
                for (var key:String in data)
                {
                    var value:Object = normalizeJsonKeys(data[key]);
                    if (key in JsonKeys) key = JsonKeys[key];
                    out[key] = value;
                }
                return out;
            }
        }

        private static const JsonKeys:Object =
        {
            // fix inconsistent names
            ANIMATION: "animation",
            ATLAS_SPRITE_instance: "atlasSpriteInstance",
            DecomposedMatrix: "decomposedMatrix",
            Frames: "frames",
            framerate: "frameRate",
            Instance_Name: "instanceName",
            Layer_name: "layerName",
            LAYERS: "layers",
            Matrix3D: "matrix3D",
            Position: "position",
            Rotation: "rotation",
            Scaling: "scaling",
            SYMBOL_DICTIONARY: "symbolDictionary",
            SYMBOL_Instance: "symbolInstance",
            SYMBOL_name: "symbolName",
            Symbols: "symbols",
            TIMELINE: "timeline",

            // fix shortened names
            AN: "animation",
            AM: "alphaMultiplier",
            ASI: "atlasSpriteInstance",
            BM: "bitmap",
            C: "color",
            DU: "duration",
            E: "elements",
            FF: "firstFrame",
            FR: "frames",
            FRT: "frameRate",
            I: "index",
            IN: "instanceName",
            L: "layers",
            LN: "layerName",
            LP: "loop",
            M3D: "matrix3D",
            MD: "metadata",
            M: "mode",
            N: "name",
            POS: "position",
            S: "symbols",
            SD: "symbolDictionary",
            SI: "symbolInstance",
            SN: "symbolName",
            ST: "symbolType",
            TL: "timeline",
            TRP: "transformationPoint"
        };
    }
}
