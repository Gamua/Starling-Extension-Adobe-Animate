package
{
    import flash.ui.Keyboard;

    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.extensions.animate.Animation;
    import starling.extensions.animate.AssetManagerEx;

    public class Demo extends Sprite
    {
        private var _ninja:Animation;
        private var _bunny:Animation;
        private var _walking:Boolean;

        public function Demo()
        { }

        public function start(assets:AssetManagerEx):void
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP,   onKeyUp);

            var background:Image = new Image(assets.getTexture("background"));
            background.alignPivot();
            background.x = stage.stageWidth / 2;
            background.y = stage.stageHeight / 2;
            addChild(background);

            _ninja = assets.createAnimation("ninja-girl");
            _ninja.x = background.x;
            _ninja.y = background.y + background.height * 0.2;
            _ninja.frameRate = 24;
            _ninja.scale = 0.75;
            addChild(_ninja);
            Starling.juggler.add(_ninja);

            _ninja.addFrameAction(_ninja.getNextLabel("idle"), gotoIdleOrWalk);
            _ninja.addFrameAction(_ninja.getNextLabel("crouch"), gotoIdleOrWalk);
            _ninja.addFrameAction(_ninja.getNextLabel("attack"), gotoIdleOrWalk);
            _ninja.addFrameAction(_ninja.getNextLabel("walk"), gotoIdleOrWalk);

            _bunny = assets.createAnimation("bunny");
            _bunny.addEventListener(Event.COMPLETE, switchBunnyDirection);
            _bunny.x = background.x;
            addChild(_bunny);
            Starling.juggler.add(_bunny);

            switchBunnyDirection(); // init bunny position
        }

        private function gotoIdleOrWalk():void
        {
            var targetLabel:String = _walking ? "walk" : "idle";

            if (_ninja.currentLabel != targetLabel)
                _ninja.gotoFrame(targetLabel);
        }

        private function onKeyDown(e:Event, keyCode:uint):void
        {
            var currentLabel:String = _ninja.currentLabel;

            if (keyCode == Keyboard.RIGHT)
            {
                _walking = true;
                _ninja.scaleX = Math.abs(_ninja.scaleX);
                gotoIdleOrWalk();
            }
            else if (keyCode == Keyboard.LEFT)
            {
                _walking = true;
                _ninja.scaleX = -Math.abs(_ninja.scaleX);
                gotoIdleOrWalk();
            }
            else if (keyCode == Keyboard.DOWN && currentLabel != "crouch")
                _ninja.gotoFrame("crouch");
            else if (keyCode == Keyboard.UP && currentLabel != "attack")
                _ninja.gotoFrame("attack");
            else if (keyCode == Keyboard.X)
                Starling.context.dispose();
            else if (keyCode == Keyboard.P)
                _ninja.isPlaying ? _ninja.pause() : _ninja.play();
            else if (keyCode == Keyboard.S)
                _ninja.stop();
        }

        private function onKeyUp(e:Event, keyCode:uint):void
        {
            if (keyCode == Keyboard.RIGHT || keyCode == Keyboard.LEFT)
            {
                _walking = false;
                gotoIdleOrWalk();
            }
        }

        private function switchBunnyDirection():void
        {
            var centerY:Number = stage.stageHeight / 2;

            if (_bunny.scaleX > 0)
            {
                _bunny.y = centerY + 22;
                _bunny.scaleY =  0.35;
                _bunny.scaleX = -0.35;
                addChildAt(_bunny, 1); // behind ninja
            }
            else
            {
                _bunny.y = centerY + 100;
                _bunny.scale = 0.5;
                addChild(_bunny); // in front of ninja
            }
        }

        // this is a simple (dead ugly) test animation used to experiment with features
        public function startAlt(assets:AssetManagerEx):void
        {
            _ninja = assets.createAnimation("simple-animation");
            _ninja.x = 300;
            _ninja.y = 600;
            _ninja.frameRate = 24;
            addChild(_ninja);

            Starling.juggler.add(_ninja);
        }
    }
}
