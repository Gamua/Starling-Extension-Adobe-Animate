package
{
    import flash.display.Sprite;
    import flash.geom.Rectangle;

    import starling.core.Starling;

    [SWF(width="320", height="480", frameRate="60", backgroundColor="#ffffff")]
    public class StartupMobile extends Sprite
    {
        private var _starling:Starling;

        public function StartupMobile()
        {
            start();
        }

        private function start():void
        {
            var viewPort:Rectangle = new Rectangle(0, 0,
                stage.fullScreenWidth, stage.fullScreenHeight);

            _starling = new Starling(Demo, stage, viewPort);
            _starling.skipUnchangedFrames = true;
            _starling.start();
        }
    }
}
