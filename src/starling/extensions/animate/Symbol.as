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
        private var _composedFrame:int;
        private var _layers:Sprite;
        private var _bitmap:Image;
        private var _numFrames:int;
        private var _numLayers:int;

        private static const sMatrix:Matrix = new Matrix();

        public function Symbol(data:Object, atlas:AnimationAtlas)
        {
            _data = data;
            _atlas = atlas;
            _composedFrame = -1;
            _numLayers = data.TIMELINE.LAYERS.length;
            _numFrames = getNumFrames();
            _symbolName = data.SYMBOL_name;
            _type = SymbolType.GRAPHIC;
            _loop = LoopMode.LOOP;

            createLayers();
        }

        public function reset():void
        {
            sMatrix.identity();
            transformationMatrix = sMatrix;
            alpha = 1.0;
            _currentFrame = 0;
            _composedFrame = -1;
        }

        /** To be called whenever sufficient time for one frame has passed. Does not necessarily
         *  move 'currentFrame' ahead - depending on the 'loop' mode. MovieClips all move
         *  forward, though (recursively). */
        public function nextFrame():void
        {
            if (_loop != LoopMode.SINGLE_FRAME)
                currentFrame += 1;

            nextFrame_MovieClips();
        }

        /** Moves all movie clips ahead one frame, recursively. */
        protected function nextFrame_MovieClips():void
        {
            if (_type == SymbolType.MOVIE_CLIP)
                currentFrame += 1;

            for (var l:int=0; l<_numLayers; ++l)
            {
                var layer:Sprite = getLayer(l);
                var numElements:int = layer.numChildren;

                for (var e:int=0; e<numElements; ++e)
                    (layer.getChildAt(e) as Symbol).nextFrame_MovieClips();
            }
        }

        protected function update():void
        {
            for (var i:int = 0; i<_numLayers; ++i)
                updateLayer(i);

            _composedFrame = _currentFrame;
        }

        private function updateLayer(layerIndex:int):void
        {
            var layer:Sprite = getLayer(layerIndex);
            var frameData:Object = getFrameData(layerIndex, _currentFrame);
            var elements:Array = frameData ? frameData.elements : null;
            var numElements:int = elements ? elements.length : 0;

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
                    var frameAge:int = _currentFrame - frameData.index;

                    if (newSymbol.loop == LoopMode.SINGLE_FRAME)
                        newSymbol.currentFrame = firstFrame;
                    else if (newSymbol.loop == LoopMode.LOOP)
                        newSymbol.currentFrame = (firstFrame + frameAge) % newSymbol._numFrames;
                    else
                        newSymbol.currentFrame = firstFrame + frameAge;
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
            else _loop = LoopMode.LOOP;
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

        protected function getLayer(layerIndex:int):Sprite
        {
            return _layers.getChildAt(layerIndex) as Sprite;
        }

        public function get currentFrame():int { return _currentFrame; }
        public function set currentFrame(value:int):void
        {
            while (value < 0) value += _numFrames;

            if (_loop == LoopMode.PLAY_ONCE)
                _currentFrame = MathUtil.clamp(value, 0, _numFrames - 1);
            else
                _currentFrame = Math.abs(value % _numFrames);

            if (_composedFrame != _currentFrame)
                update();
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
    }
}
