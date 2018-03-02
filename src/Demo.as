package
{
    import flash.filesystem.File;
    import flash.system.System;
    import flash.ui.Keyboard;

    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.extensions.animate.Animation;
    import starling.extensions.animate.AssetManagerEx;

    public class Demo extends Sprite
    {
        private var _assets:AssetManagerEx;
        private var _animation:Animation;

        public function Demo()
        {
            addEventListener(Event.ADDED_TO_STAGE, init);
        }

        public function init():void
        {
            var appDir:File = File.applicationDirectory;

            _assets = new AssetManagerEx();
            _assets.enqueue(appDir.resolvePath("assets/NinjaGirl/"));
            _assets.loadQueue(onAssetsLoaded);

            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        private function onAssetsLoaded():void
        {
            // now would be a good time for a clean-up
            System.pauseForGCIfCollectionImminent(0);
            System.gc();

            _animation = _assets.createAnimation("NinjaGirl");
            _animation.x = 300;
            _animation.y = 600;
            _animation.frameRate = 24;
            addChild(_animation);

            Starling.juggler.add(_animation);
        }

        private function onKeyDown(e:Event, keyCode:uint):void
        {
            if (keyCode == Keyboard.RIGHT && _animation)
                _animation.currentFrame += 1;
            else if (keyCode == Keyboard.LEFT && _animation)
                _animation.currentFrame -= 1;
        }
    }
}
