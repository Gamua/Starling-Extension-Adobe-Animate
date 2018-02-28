package starling.extensions.animate
{
    import flash.geom.Matrix;

    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.MathUtil;

    public class Symbol extends DisplayObjectContainer
    {
        public static const BITMAP_SYMBOL_NAME:String = "___atlas_sprite___";

        private var _data:Object;
        private var _symbolName:String;
        private var _type:String;
        private var _loop:String;
        private var _currentFrame:int;
        private var _layers:Sprite;
        private var _bitmap:Image;
        private var _numFrames:int;
        private var _numLayers:int;

        private static const sMatrix:Matrix = new Matrix();
        private static const STD_MATRIX3D_DATA:Object = {
            "m00": 1, "m01": 0, "m02": 0, "m03": 0,
            "m10": 0, "m11": 1, "m12": 0, "m13": 0,
            "m20": 0, "m21": 0, "m22": 1, "m23": 0,
            "m30": 0, "m31": 0, "m32": 0, "m33": 1
        };

        public function Symbol(data:Object)
        {
            _data = data;
            _numLayers = data.TIMELINE.LAYERS.length;
            _numFrames = getNumFrames();
            _symbolName = data.SYMBOL_name;
            _type = SymbolType.MOVIE_CLIP;
            _loop = LoopMode.LOOP;

            createLayers();
            preProcessData();
            addEventListener(Event.ADDED, onAdded);
        }

        public function reset():void
        {
            sMatrix.identity();
            transformationMatrix = sMatrix;
            alpha = 1.0;
            currentFrame = 0;
        }

        private function onAdded():void
        {
            if (animation)
            {
                removeEventListener(Event.ADDED, onAdded);
                advanceLayers();
            }
        }

        public function nextFrame():void
        {
            currentFrame = _currentFrame + 1;
        }

        private function get animation():Animation
        {
            var object:DisplayObject = this;

            while (object && !(object is Animation))
                object = object.parent;

            return object as Animation;
        }

        private function getLayer(layerIndex:int):Sprite
        {
            return _layers.getChildAt(layerIndex) as Sprite;
        }

        public function get currentFrame():int { return _currentFrame; }
        public function set currentFrame(value:int):void
        {
            _currentFrame = MathUtil.max(value, 0);

            if (animation)
                advanceLayers();
            else
                addEventListener(Event.ADDED, onAdded);
        }

        private function advanceLayers():void
        {
            for (var i:int = 0, len:int = numLayers; i<len; ++i)
                advanceLayer(i);
        }

        private function advanceLayer(layerIndex:int):void
        {
            var frameIndex:int = _loop == LoopMode.LOOP ?
                _currentFrame % _numFrames : MathUtil.max(_currentFrame, _numFrames - 1);

            var animation:Animation = this.animation;
            var layer:Sprite = getLayer(layerIndex);
            var frameData:Object = getFrameData(layerIndex, frameIndex);
            var elements:Array = frameData ? frameData.elements : null;
            var numElements:int = elements ? elements.length : 0;

            for (var i:int=0; i<numElements; ++i)
            {
                var elementData:Object = elements[i].SYMBOL_Instance;
                var oldSymbol:Symbol = layer.numChildren > i ? layer.getChildAt(i) as Symbol : null;
                var newSymbol:Symbol = null;
                var symbolName:String = elementData.SYMBOL_name;

                if (!animation.hasSymbol(symbolName))
                    symbolName = BITMAP_SYMBOL_NAME;

                if (oldSymbol && oldSymbol._symbolName == symbolName)
                    newSymbol = oldSymbol;
                else
                {
                    if (oldSymbol)
                    {
                        oldSymbol.removeFromParent();
                        animation.putSymbol(oldSymbol);
                    }

                    newSymbol = animation.getSymbol(symbolName);
                    layer.addChildAt(newSymbol, i);
                }

                newSymbol.setTransformationMatrix(elementData.Matrix3D);
                newSymbol.setBitmap(elementData.bitmap);
                newSymbol.setColor(elementData.color);
                newSymbol.setLoop(elementData.loop);
                newSymbol.setType(elementData.symbolType);

                if (newSymbol.type == SymbolType.GRAPHIC)
                {
                    var firstFrame:int = elementData.firstFrame;
                    var frameAge:int = frameIndex - frameData.index;

                    if (newSymbol.loop == LoopMode.SINGLE_FRAME)
                        newSymbol.currentFrame = firstFrame;
                    else
                        newSymbol.currentFrame = firstFrame + frameAge;
                }
                else if (newSymbol.type == SymbolType.MOVIE_CLIP)
                {
                    newSymbol.currentFrame += 1;
                }
            }

            var numObsoleteSymbols:int = layer.numChildren - numElements;

            for (i=0; i<numObsoleteSymbols; ++i)
            {
                oldSymbol = layer.removeChildAt(numElements) as Symbol;
                animation.putSymbol(oldSymbol);
            }
        }

        private function createLayers():void
        {
            if (_layers) throw new Error("Method must only be called once");

            _layers = new Sprite();
            addChild(_layers);

            for (var i:int = 0; i<_numLayers; ++i)
            {
                var layer:Sprite = new Sprite();
                layer.name = getLayerData(i).Layer_name;
                _layers.addChild(layer);
            }
        }

        private function preProcessData():void
        {
            // In Animate CC, layers are sorted front to back.
            // In Starling, it's the other way round - so we simply reverse the layer data.

            _data.TIMELINE.LAYERS.reverse();

            // We replace all "ATLAS_SPRITE_instance" elements with symbols of the same contents.
            // That way, we are always only dealing with symbols.

            var numLayers:int = this.numLayers;

            for (var l:int=0; l<numLayers; ++l)
            {
                var layerData:Object = getLayerData(l);
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
                            elements[e] = {
                                SYMBOL_Instance: {
                                    SYMBOL_name: BITMAP_SYMBOL_NAME,
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
                    }
                }
            }
        }

        public function setBitmap(data:Object):void
        {
            if (data)
            {
                var texture:Texture = animation.getTexture(data.name);

                if (_bitmap)
                {
                    _bitmap.texture = texture;
                    _bitmap.readjustSize();
                }
                else
                {
                    _bitmap = animation.getImage(texture);
                    addChild(_bitmap);
                }

                _bitmap.x = data.Position.x;
                _bitmap.y = data.Position.y;
            }
            else if (_bitmap)
            {
                _bitmap.x = _bitmap.y = 0;
                _bitmap.removeFromParent();
                animation.putImage(_bitmap);
                _bitmap = null;
            }
        }

        private function setTransformationMatrix(data:Object):void
        {
            sMatrix.setTo(data.m00, data.m01, data.m10, data.m11, data.m30, data.m31);
            transformationMatrix = sMatrix;
        }

        private function setPivot(data:Object):void
        {
            pivotX = data.x; pivotY = data.y;
        }

        private function setColor(data:Object):void
        {
            if (data)
            {
                alpha = data.mode == "Alpha" ? data.alphaMultiplier : 1.0;
            }
            else
            {
                alpha = 1.0;
            }
        }

        private function setLoop(data:String):void
        {
            if (data) _loop = data;
        }

        private function setType(data:String):void
        {
            if (data) _type = data;
        }

        private function getNumFrames():int
        {
            var numFrames:int = 0;
            var numLayers:int = this.numLayers;

            for (var i:int=0; i<numLayers; ++i)
            {
                var frameDates:Array = getLayerData(i).Frames as Array;
                var numFrameDates:int = frameDates ? frameDates.length : 0;
                var layerNumFrames:int = numFrameDates ? frameDates[0].index : 0;

                for (var j:int=0; j<numFrameDates; ++j)
                    layerNumFrames += frameDates[j].duration;

                if (layerNumFrames > numFrames)
                    numFrames = layerNumFrames;
            }

            return numFrames || 1;
        }

        public function get type():String { return _type; }
        public function set type(value:String):void
        {
            if (SymbolType.isValid(value)) _type = value;
            else throw new ArgumentError("Invalid symbol type: " + value);
        }

        public function get loop():String { return _loop; }
        public function set loop(value:String):void
        {
            if (LoopMode.isValid(value)) _loop = value;
            else throw new ArgumentError("Invalid loop mode: " + value);
        }

        public function get symbolName():String { return _symbolName; }
        public function get instanceName():String { return name; }
        public function get numLayers():int { return _numLayers; }
        public function get numFrames():int { return _numFrames; }

        // data access

        private function getLayerData(layerIndex:int):Object
        {
            return _data.TIMELINE.LAYERS[layerIndex];
        }

        private function getFrameData(layerIndex:int, frameIndex:int):Object
        {
            var frames:Array = getLayerData(layerIndex).Frames;
            var numFrames:int = frames.length;

            for (var i:int=0; i<numFrames; ++i)
            {
                var frame:Object = frames[i];
                if (frame.index <= frameIndex && frame.index + frame.duration > frameIndex)
                    return frame;
            }

            return null;
        }

        private function getElementData(layerIndex:int, frameIndex:int, elementIndex:int):Object
        {
            return getFrameData(layerIndex, frameIndex).elements[elementIndex];
        }
    }
}
