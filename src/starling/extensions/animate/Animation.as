package starling.extensions.animate
{
    import flash.utils.Dictionary;

    import starling.animation.IAnimatable;
    import starling.display.Image;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;

    public class Animation extends Symbol implements IAnimatable
    {
        private var _atlas:TextureAtlas;
        private var _symbolData:Dictionary;
        private var _symbolPool:Dictionary;
        private var _imagePool:Array;
        private var _frameRate:int;
        private var _currentTime:Number;

        public function Animation(data:Object, atlas:TextureAtlas)
        {
            super(data.ANIMATION);

            _frameRate = data.metadata.framerate;
            _atlas = atlas;
            _symbolPool = new Dictionary();
            _symbolData = createSymbolData(data.SYMBOL_DICTIONARY);
            _imagePool = [];
            _currentTime = 0;
        }

        private function createSymbolData(data:Object):Dictionary
        {
            var dict:Dictionary = new Dictionary();

            for each (var symbolData:Object in data.Symbols)
                dict[symbolData.SYMBOL_name] = symbolData;

            dict[Symbol.BITMAP_SYMBOL_NAME] = {
                SYMBOL_name: Symbol.BITMAP_SYMBOL_NAME,
                TIMELINE: { LAYERS: [] }
            };

            return dict;
        }

        public function advanceTime(time:Number):void
        {
            _currentTime += time;
            currentFrame = _currentTime * _frameRate;
        }

        override public function set currentFrame(value:int):void
        {
            if (value != currentFrame)
                super.currentFrame = value;
        }

        internal function getTexture(name:String):Texture
        {
            return _atlas.getTexture(name);
        }

        internal function getImage(texture:Texture):Image
        {
            if (_imagePool.length == 0) return new Image(texture);
            else
            {
                var image:Image = _imagePool.pop() as Image;
                image.texture = texture;
                image.readjustSize();
                return image;
            }
        }

        internal function putImage(image:Image):void
        {
            _imagePool[_imagePool.length] = image;
        }

        internal function hasSymbol(name:String):Boolean
        {
            return name in _symbolData;
        }

        internal function getSymbol(name:String):Symbol
        {
            var pool:Array = getSymbolPool(name);
            if (pool.length == 0) return new Symbol(_symbolData[name]);
            else return pool.pop();
        }

        internal function putSymbol(symbol:Symbol):void
        {
            symbol.reset();
            var pool:Array = getSymbolPool(symbol.symbolName);
            pool[pool.length] = symbol;
            symbol.currentFrame = 0;
        }

        private function getSymbolPool(name:String):Array
        {
            var pool:Array = _symbolPool[name];
            if (pool == null) pool = _symbolPool[name] = [];
            return pool;
        }

        public function get frameRate():int { return _frameRate; }
    }
}
