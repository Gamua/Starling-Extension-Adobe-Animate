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
            assets.enqueue(EmbeddedAssets);
            assets.loadQueue(demo.start);
        }
    }
}

class EmbeddedAssets
{
    // It's important to follow these naming conventions when embedding "Animate CC" animations.
    //
    // file name: [name]/Animation.json -> member name: [name]_animation
    // file name: [name]/spritemap.json -> member name: [name]_spritemap
    // file name: [name]/spritemap.png  -> member name: [name]

    [Embed(source="../assets/ninja-girl/Animation.json", mimeType="application/octet-stream")]
    public static const ninja_girl_animation:Class;

    [Embed(source="../assets/ninja-girl/spritemap.json", mimeType="application/octet-stream")]
    public static const ninja_girl_spritemap:Class;

    [Embed(source="../assets/ninja-girl/spritemap.png")]
    public static const ninja_girl:Class;

    [Embed(source="../assets/bunny/Animation.json", mimeType="application/octet-stream")]
    public static const bunny_animation:Class;

    [Embed(source="../assets/bunny/spritemap.json", mimeType="application/octet-stream")]
    public static const bunny_spritemap:Class;

    [Embed(source="../assets/bunny/spritemap.png")]
    public static const bunny:Class;

    [Embed(source="../assets/background.jpg")]
    public static const background:Class;
}
