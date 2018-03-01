package starling.extensions.animate
{
    import starling.animation.IAnimatable;

    public class Animation extends Symbol implements IAnimatable
    {
        private var _atlas:AnimationAtlas;
        private var _currentTime:Number;

        public function Animation(data:Object, atlas:AnimationAtlas)
        {
            super(data, atlas);

            _atlas = atlas;
            _currentTime = 0;

            recompose();
        }

        public function advanceTime(time:Number):void
        {
            _currentTime += time;
            currentFrame = _currentTime * frameRate;
        }

        override public function set currentFrame(value:int):void
        {
            if (value != currentFrame)
                super.currentFrame = value;
        }

        public function get frameRate():Number { return _atlas.frameRate; }
        public function set frameRate(value:Number):void { _atlas.frameRate = value; }
    }
}
