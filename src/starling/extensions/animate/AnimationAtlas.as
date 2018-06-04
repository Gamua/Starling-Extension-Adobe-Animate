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
            return new Animation(getSymbolData(name), this);
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
            for each (var symbolData:Object in data.SYMBOL_DICTIONARY.Symbols)
                _symbolData[symbolData.SYMBOL_name] = preprocessSymbolData(symbolData);

            // the main animation
            var defaultSymbolData:Object = preprocessSymbolData(data.ANIMATION);
            _defaultSymbolName = defaultSymbolData.SYMBOL_name;
            _symbolData[_defaultSymbolName] = defaultSymbolData;

            // a purely internal symbol for bitmaps - simplifies their handling
            _symbolData[Symbol.BITMAP_SYMBOL_NAME] = {
                SYMBOL_name: Symbol.BITMAP_SYMBOL_NAME,
                TIMELINE: { LAYERS: [] }
            };
        }

        private static function preprocessSymbolData(symbolData:Object):Object
        {
            var timeLineData:Object = symbolData.TIMELINE;
            var layerDates:Array = timeLineData.LAYERS;

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
                var frames:Array = layerData.Frames as Array;
                var numFrames:int = frames.length;

                for (var f:int=0; f<numFrames; ++f)
                {
                    var elements:Array = frames[f].elements as Array;
                    var numElements:int = elements.length;

                    for (var e:int=0; e<numElements; ++e)
                    {
                        var element:Object = elements[e];

                        if ("ATLAS_SPRITE_instance" in element)
                        {
                            element = elements[e] = {
                                SYMBOL_Instance: {
                                    SYMBOL_name: Symbol.BITMAP_SYMBOL_NAME,
                                    Instance_Name: "InstName",
                                    bitmap: element.ATLAS_SPRITE_instance,
                                    symbolType: SymbolType.GRAPHIC,
                                    firstFrame: 0,
                                    loop: LoopMode.LOOP,
                                    transformationPoint: { x: 0, y: 0 },
                                    Matrix3D: STD_MATRIX3D_DATA
                                }
                            }
                        }

                        // not needed - remove decomposed matrix to save some memory
                        delete element.SYMBOL_Instance.DecomposedMatrix;
                    }
                }
            }

            return symbolData;
        }

        private function getSymbolData(name:String):Object
        {
            return _symbolData[name];
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
    }
}
