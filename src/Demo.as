package
{
    import flash.filesystem.File;
    import flash.ui.Keyboard;

    import starling.assets.AssetManager;
    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.extensions.animate.AnimateFactory;
    import starling.extensions.animate.Animation;
    import starling.textures.TextureAtlas;

    public class Demo extends Sprite
    {
        private var _assets:AssetManager;
        private var _animation:Animation;

        public function Demo()
        {
            addEventListener(Event.ADDED_TO_STAGE, init);
        }

        public function init():void
        {
            _assets = new AssetManager();
            _assets.registerFactory(new AnimateFactory(), 10);

            var appDir:File = File.applicationDirectory;
            _assets.enqueue(appDir.resolvePath("assets/Joker/"));
            _assets.loadQueue(onAssetsLoaded);

            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        private function onAssetsLoaded():void
        {
            var animationAtlas:TextureAtlas = _assets.getTextureAtlas("spritemap");
            var animationData:Object = _assets.getObject("Animation");

            _animation = new Animation(animationData, animationAtlas);
            _animation.x = 300;
            _animation.y = 600;
            _animation.scale = 0.5;
            addChild(_animation);

            Starling.juggler.add(_animation);
        }

        private function onKeyDown(e:Event, keyCode:uint):void
        {
            if (keyCode == Keyboard.RIGHT && _animation)
                _animation.nextFrame();
            else if (keyCode == Keyboard.LEFT && _animation)
                _animation.currentFrame -= 1;
        }
    }
}
