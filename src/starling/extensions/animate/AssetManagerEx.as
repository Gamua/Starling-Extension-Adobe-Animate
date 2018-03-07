package starling.extensions.animate
{
    import starling.assets.AssetManager;

    public class AssetManagerEx extends AssetManager
    {
        // helper objects
        private static var sNames:Vector.<String> = new <String>[];

        public function AssetManagerEx()
        {
            registerFactory(new AnimationAtlasFactory(), 10);
        }

        override public function addAsset(name:String, asset:Object, type:String = null):void
        {
            if (type == null && asset is AnimationAtlas)
                type = AnimationAtlas.ASSET_TYPE;

            super.addAsset(name, asset, type);
        }

        /** Returns an animation atlas with a certain name, or null if it's not found. */
        public function getAnimationAtlas(name:String):AnimationAtlas
        {
            return getAsset(AnimationAtlas.ASSET_TYPE, name) as AnimationAtlas;
        }

        /** Returns all animation atlas names that start with a certain string, sorted alphabetically.
         *  If you pass an <code>out</code>-vector, the names will be added to that vector. */
        public function getAnimationAtlasNames(prefix:String="", out:Vector.<String>=null):Vector.<String>
        {
            return getAssetNames(AnimationAtlas.ASSET_TYPE, prefix, true, out);
        }

        public function createAnimation(name:String):Animation
        {
            var atlasNames:Vector.<String> = getAnimationAtlasNames("", sNames);
            var animation:Animation = null;

            for each (var atlasName:String in atlasNames)
            {
                var atlas:AnimationAtlas = getAnimationAtlas(atlasName);
                if (atlas.hasAnimation(name))
                {
                    animation = atlas.createAnimation(name);
                    break;
                }
            }

            if (animation == null && atlasNames.indexOf(name) != -1)
                animation = getAnimationAtlas(name).createAnimation();

            sNames.length = 0;
            return animation;
        }

        override protected function getNameFromUrl(url:String):String
        {
            var defaultName:String = super.getNameFromUrl(url);
            var separator:String = "/";

            if (defaultName == "Animation" || defaultName == "spritemap" &&
                url.indexOf(separator) != -1)
            {
                var elements:Array = url.split(separator);
                var folderName:String = elements[elements.length - 2];
                var suffix:String = defaultName == "Animation" ? AnimationAtlasFactory.ANIMATION_SUFFIX : "";
                return super.getNameFromUrl(folderName + suffix);
            }

            return defaultName;
        }
    }
}

import flash.geom.Rectangle;

import starling.assets.AssetFactoryHelper;
import starling.assets.AssetManager;
import starling.assets.AssetReference;
import starling.assets.JsonFactory;
import starling.extensions.animate.AnimationAtlas;
import starling.textures.SubTexture;
import starling.textures.Texture;
import starling.textures.TextureAtlas;
import starling.utils.Pool;

class AnimationAtlasFactory extends JsonFactory
{
    public static const ANIMATION_SUFFIX:String = "_animation";
    public static const SPRITEMAP_SUFFIX:String = "_spritemap";

    override public function create(reference:AssetReference, helper:AssetFactoryHelper,
                                    onComplete:Function, onError:Function):void
    {
        super.create(reference, helper, onObjectComplete, onError);

        function onObjectComplete(name:String, json:Object):void
        {
            if (json.ATLAS && json.meta)
            {
                helper.addPostProcessor(function(assets:AssetManager):void
                {
                    if (name.indexOf(SPRITEMAP_SUFFIX) == name.length - SPRITEMAP_SUFFIX.length)
                        name = name.substr(0, name.length - SPRITEMAP_SUFFIX.length);

                    var textureName:String = helper.getNameFromUrl(name);
                    var texture:Texture = assets.getTexture(textureName);

                    assets.addAsset(name, new JsonTextureAtlas(texture, json));
                }, 100);
            }
            else if (json.ANIMATION && json.SYMBOL_DICTIONARY)
            {
                helper.addPostProcessor(function(assets:AssetManager):void
                {
                    var suffixIndex:int = name.indexOf(ANIMATION_SUFFIX);
                    var baseName:String = name.substr(0,
                        suffixIndex >= 0 ? suffixIndex : int.MAX_VALUE);

                    assets.addAsset(baseName, new AnimationAtlas(json,
                        assets.getTextureAtlas(baseName)), AnimationAtlas.ASSET_TYPE);
                });
            }

            onComplete(name, json);
        }
    }
}

class JsonTextureAtlas extends TextureAtlas
{
    public function JsonTextureAtlas(texture:Texture, data:*=null)
    {
        super(texture, data);
    }

    override protected function parseAtlasData(data:*):void
    {
        if (data is Object) parseAtlasJson(data as Object);
        else super.parseAtlasData(data);
    }

    private function parseAtlasJson(data:Object):void
    {
        var region:Rectangle = Pool.getRectangle();

        for each (var element:Object in data.ATLAS.SPRITES)
        {
            var node:Object = element.SPRITE;
            region.setTo(node.x, node.y, node.w, node.h);
            var subTexture:SubTexture = new SubTexture(texture, region, false, null, node.rotated);
            addSubTexture(node.name, subTexture);
        }

        Pool.putRectangle(region);
    }
}