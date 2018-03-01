package starling.extensions.animate
{
    import flash.geom.Matrix;

    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.utils.MathUtil;

    public class Symbol extends DisplayObjectContainer
    {
        public static const BITMAP_SYMBOL_NAME:String = "___atlas_sprite___";

        private var _data:Object;
        private var _atlas:AnimationAtlas;
        private var _symbolName:String;
        private var _type:String;
        private var _loop:String;
        private var _currentFrame:int;
        private var _layers:Sprite;
        private var _bitmap:Image;
        private var _numFrames:int;
        private var _numLayers:int;

        private static const sMatrix:Matrix = new Matrix();

        public function Symbol(data:Object, atlas:AnimationAtlas)
        {
            _data = data;
            _atlas = atlas;
            _numLayers = data.TIMELINE.LAYERS.length;
            _numFrames = getNumFrames();
            _symbolName = data.SYMBOL_name;
            _type = SymbolType.MOVIE_CLIP;
            _loop = LoopMode.LOOP;

            createLayers();
        }

        public function reset():void
        {
            sMatrix.identity();
            transformationMatrix = sMatrix;
            alpha = 1.0;
            _currentFrame = 0;
        }

        public function nextFrame():void
        {
            currentFrame = _currentFrame + 1;
        }

        public function recompose():void
        {
            for (var i:int = 0; i<_numLayers; ++i)
                advanceLayer(i);
        }

        private function getLayer(layerIndex:int):Sprite
        {
            return _layers.getChildAt(layerIndex) as Sprite;
        }

        public function get currentFrame():int { return _currentFrame; }
        public function set currentFrame(value:int):void
        {
            _currentFrame = MathUtil.max(value, 0);
            recompose();
        }

        private function advanceLayer(layerIndex:int):void
        {
            var frameIndex:int = _loop == LoopMode.LOOP ?
                _currentFrame % _numFrames : MathUtil.min(_currentFrame, _numFrames - 1);

            var layer:Sprite = getLayer(layerIndex);
            var frameData:Object = getFrameData(layerIndex, frameIndex);
            var elements:Array = frameData ? frameData.elements : null;
            var numElements:int = elements ? elements.length : 0;

//            if (layer.name == "starling_beak")
//                trace(".");

            for (var i:int=0; i<numElements; ++i)
            {
                var elementData:Object = elements[i].SYMBOL_Instance;
                var oldSymbol:Symbol = layer.numChildren > i ? layer.getChildAt(i) as Symbol : null;
                var newSymbol:Symbol = null;
                var symbolName:String = elementData.SYMBOL_name;

                if (!_atlas.hasSymbol(symbolName))
                    symbolName = BITMAP_SYMBOL_NAME;

                if (oldSymbol && oldSymbol._symbolName == symbolName)
                    newSymbol = oldSymbol;
                else
                {
                    if (oldSymbol)
                    {
                        oldSymbol.removeFromParent();
                        _atlas.putSymbol(oldSymbol);
                    }

                    newSymbol = _atlas.getSymbol(symbolName);
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
                _atlas.putSymbol(oldSymbol);
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

        public function setBitmap(data:Object):void
        {
            if (data)
            {
                var texture:Texture = _atlas.getTexture(data.name);

                if (_bitmap)
                {
                    _bitmap.texture = texture;
                    _bitmap.readjustSize();
                }
                else
                {
                    _bitmap = _atlas.getImage(texture);
                    addChild(_bitmap);
                }

                _bitmap.x = data.Position.x;
                _bitmap.y = data.Position.y;
            }
            else if (_bitmap)
            {
                _bitmap.x = _bitmap.y = 0;
                _bitmap.removeFromParent();
                _atlas.putImage(_bitmap);
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
