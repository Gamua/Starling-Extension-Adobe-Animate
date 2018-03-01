package starling.extensions.animate
{
    import starling.animation.IAnimatable;

    public class Animation extends Symbol implements IAnimatable
    {
        private var _atlas:AnimationAtlas;
        private var _currentTime:Number;
        private var _frameRate:Number;

        public function Animation(data:Object, atlas:AnimationAtlas)
        {
            super(data, atlas);

            _atlas = atlas;
            _currentTime = 0;
            _frameRate = _atlas.frameRate;

            update();
        }

        public function advanceTime(time:Number):void
        {
            var prevTime:Number = _currentTime;
            _currentTime += time;

            if (int(prevTime * _frameRate) != int(_currentTime * _frameRate)) // frame changes
            {
                if (loop != LoopMode.SINGLE_FRAME && type != SymbolType.MOVIE_CLIP)
                    currentFrame = _currentTime * _frameRate;

                nextFrame_MovieClips();
            }
        }

        public function get frameRate():Number { return _frameRate; }
        public function set frameRate(value:Number):void { _frameRate = value; }
    }
}
