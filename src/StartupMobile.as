package
{
    import flash.display.Sprite;
    import flash.filesystem.File;
    import flash.geom.Rectangle;

    import starling.core.Starling;
    import starling.events.Event;
    import starling.extensions.animate.AssetManagerEx;

    [SWF(width="320", height="480", frameRate="60", backgroundColor="#ffffff")]
    public class StartupMobile extends Sprite
    {
        private var _starling:Starling;

        public function StartupMobile()
        {
            var viewPort:Rectangle = new Rectangle(0, 0,
                stage.fullScreenWidth, stage.fullScreenHeight);

            _starling = new Starling(Demo, stage, viewPort);
            _starling.skipUnchangedFrames = true;
            _starling.addEventListener(Event.ROOT_CREATED, loadAssets);
            _starling.start();
        }

        private function loadAssets():void
        {
            var demo:Demo = _starling.root as Demo;
            var appDir:File = File.applicationDirectory;
            var assets:AssetManagerEx = new AssetManagerEx();
            assets.enqueue(appDir.resolvePath("assets/ninja-girl/"));
            assets.enqueue(appDir.resolvePath("assets/bunny/"));
            assets.enqueue(appDir.resolvePath("assets/background.jpg"));
            assets.loadQueue(demo.start);
        }
    }
}
