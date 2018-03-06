package
{
    import flash.display.Sprite;

    import starling.core.Starling;
    import starling.events.Event;
    import starling.extensions.animate.AssetManagerEx;

    [SWF(width="500", height="500", frameRate="60", backgroundColor="#eeeeee")]
    public class StartupWeb extends Sprite
    {
        private var _starling:Starling;

        public function StartupWeb()
        {
            _starling = new Starling(Demo, stage);
            _starling.skipUnchangedFrames = true;
            _starling.addEventListener(Event.ROOT_CREATED, loadAssets);
            _starling.start();
        }

        private function loadAssets():void
        {
            var demo:Demo = _starling.root as Demo;
            var assets:AssetManagerEx = new AssetManagerEx();
            var animations:Array = ["ninja-girl", "bunny"];

            for each (var anim:String in animations)
            {
                assets.enqueue("assets/" + anim + "/Animation.json");
                assets.enqueue("assets/" + anim + "/spritemap.json");
                assets.enqueue("assets/" + anim + "/spritemap.png");
            }

            assets.enqueue("assets/background.jpg");
            assets.loadQueue(demo.start);
        }
    }
}
