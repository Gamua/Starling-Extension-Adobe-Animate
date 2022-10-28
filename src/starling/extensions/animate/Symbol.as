package starling.extensions.animate
{
    import flash.display.FrameLabel;
    import flash.geom.Matrix;

    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.utils.MathUtil;

    internal class Symbol extends DisplayObjectContainer
    {
        public static const BITMAP_SYMBOL_NAME:String = "___atlas_sprite___";

        private var _data:Object;
        private var _atlas:AnimationAtlas;
        private var _symbolName:String;
        private var _type:String;
        private var _loopMode:String;
        private var _currentFrame:int;
        private var _composedFrame:int;
        private var _layers:Sprite;
        private var _bitmap:Image;
        private var _numFrames:int;
        private var _numLayers:int;
        private var _frameLabels:Array;

        private static const sMatrix:Matrix = new Matrix();

        public function Symbol(data:Object, atlas:AnimationAtlas)
        {
            _data = data;
            _atlas = atlas;
            _composedFrame = -1;
            _numLayers = data.timeline.layers.length;
            _numFrames = getNumFrames();
            _frameLabels = getFrameLabels();
            _symbolName = data.symbolName;
            _type = SymbolType.GRAPHIC;
            _loopMode = LoopMode.LOOP;

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
            if (_loopMode != LoopMode.SINGLE_FRAME)
                currentFrame += 1;

            nextFrame_MovieClips();
        }

        /** Moves all movie clips ahead one frame, recursively. */
        public function nextFrame_MovieClips():void
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

        public function update():void
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
                var elementData:Object = elements[i].symbolInstance;
                var oldSymbol:Symbol = layer.numChildren > i ? layer.getChildAt(i) as Symbol : null;
                var newSymbol:Symbol = null;
                var symbolName:String = elementData.symbolName;

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

                newSymbol.setTransformationMatrix(elementData.matrix3D);
                newSymbol.setBitmap(elementData.bitmap);
                newSymbol.setColor(elementData.color);
                newSymbol.setLoop(elementData.loop);
                newSymbol.setType(elementData.symbolType);

                if (newSymbol.type == SymbolType.GRAPHIC)
                {
                    var firstFrame:int = elementData.firstFrame;
                    var frameAge:int = _currentFrame - frameData.index;

                    if (newSymbol.loopMode == LoopMode.SINGLE_FRAME)
                        newSymbol.currentFrame = firstFrame;
                    else if (newSymbol.loopMode == LoopMode.LOOP)
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
                layer.name = getLayerData(i).layerName;
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

                if (data.position)
                {
                    _bitmap.x = data.position.x;
                    _bitmap.y = data.position.y;
                }
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

        private function setColor(data:Object):void
        {
            if (data)
            {
                var mode:String = data.mode;
                const ALPHA_MODES:Array = ["Alpha", "Advanced", "AD"];
                alpha = (ALPHA_MODES.indexOf(mode) >= 0) ? data.alphaMultiplier : 1.0;
            }
            else
            {
                alpha = 1.0;
            }
        }

        private function setLoop(data:String):void
        {
            if (data) _loopMode = LoopMode.parse(data);
            else _loopMode = LoopMode.LOOP;
        }

        private function setType(data:String):void
        {
            if (data) _type = SymbolType.parse(data);
        }

        private function getNumFrames():int
        {
            var numFrames:int = 0;

            for (var i:int=0; i<_numLayers; ++i)
            {
                var frameDates:Array = getLayerData(i).frames as Array;
                var numFrameDates:int = frameDates ? frameDates.length : 0;
                var layerNumFrames:int = numFrameDates ? frameDates[0].index : 0;

                for (var j:int=0; j<numFrameDates; ++j)
                    layerNumFrames += frameDates[j].duration;

                if (layerNumFrames > numFrames)
                    numFrames = layerNumFrames;
            }

            return numFrames || 1;
        }

        private function getFrameLabels():Array
        {
            var labels:Array = [];

            for (var i:int=0; i<_numLayers; ++i)
            {
                var frameDates:Array = getLayerData(i).frames as Array;
                var numFrameDates:int = frameDates ? frameDates.length : 0;

                for (var j:int=0; j<numFrameDates; ++j)
                {
                    var frameData:Object = frameDates[j];
                    if ("name" in frameData)
                        labels[labels.length] = new FrameLabel(frameData.name, frameData.index);
                }
            }

            labels.sortOn('frame', Array.NUMERIC);
            return labels;
        }

        private function getLayer(layerIndex:int):Sprite
        {
            return _layers.getChildAt(layerIndex) as Sprite;
        }

        public function getNextLabel(afterLabel:String=null):String
        {
            var numLabels:int = _frameLabels.length;
            var startFrame:int = getFrame(afterLabel || currentLabel);

            for (var i:int=0; i<numLabels; ++i)
            {
                var label:FrameLabel = _frameLabels[i];
                if (label.frame > startFrame) return label.name;
            }

            return _frameLabels ? _frameLabels[0].name : null; // wrap around
        }

        public function get currentLabel():String
        {
            var numLabels:int = _frameLabels.length;
            var highestLabel:FrameLabel = numLabels ? _frameLabels[0] : null;

            for (var i:int=1; i<numLabels; ++i)
            {
                var label:FrameLabel = _frameLabels[i];

                if (label.frame <= _currentFrame) highestLabel = label;
                else break;
            }

            return highestLabel ? highestLabel.name : null;
        }

        public function getFrame(label:String):int
        {
            var numLabels:int = _frameLabels.length;
            for (var i:int=0; i<numLabels; ++i)
            {
                var frameLabel:FrameLabel = _frameLabels[i];
                if (frameLabel.name == label) return frameLabel.frame;
            }
            return -1;
        }

        public function get currentFrame():int { return _currentFrame; }
        public function set currentFrame(value:int):void
        {
            while (value < 0) value += _numFrames;

            if (_loopMode == LoopMode.PLAY_ONCE)
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

        public function get loopMode():String { return _loopMode; }
        public function set loopMode(value:String):void
        {
            if (LoopMode.isValid(value)) _loopMode = value;
            else throw new ArgumentError("Invalid loop mode: " + value);
        }

        public function get symbolName():String { return _symbolName; }
        public function get numLayers():int { return _numLayers; }
        public function get numFrames():int { return _numFrames; }

        // data access

        private function getLayerData(layerIndex:int):Object
        {
            return _data.timeline.layers[layerIndex];
        }

        private function getFrameData(layerIndex:int, frameIndex:int):Object
        {
            var frames:Array = getLayerData(layerIndex).frames;
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
