package starling.extensions.animate
{
    import starling.assets.AssetManager;

    /** An AssetManager subclass that adds support for the "AnimationAtlas" asset type. */
    public class AnimAssetManager extends AssetManager
    {
        // helper objects
        private static var sNames:Vector.<String> = new <String>[];

        public function AnimAssetManager()
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
            var defaultExt:String = super.getExtensionFromUrl(url);

            if (defaultName.match(/spritemap\d?/) && (defaultExt == "png" || defaultExt == "atf"))
                return AnimationAtlasFactory.getName(url, defaultName, false);
            else
                return defaultName;
        }
    }
}

import starling.assets.AssetFactoryHelper;
import starling.assets.AssetManager;
import starling.assets.AssetReference;
import starling.assets.JsonFactory;
import starling.extensions.animate.AnimationAtlas;
import starling.extensions.animate.JsonTextureAtlas;
import starling.textures.Texture;

class AnimationAtlasFactory extends JsonFactory
{
    public static const ANIMATION_SUFFIX:String = "_animation";
    public static const SPRITEMAP_SUFFIX:String = "_spritemap";

    override public function create(asset:AssetReference, helper:AssetFactoryHelper,
                                    onComplete:Function, onError:Function):void
    {
        super.create(asset, helper, onObjectComplete, onError);

        function onObjectComplete(name:String, json:Object):void
        {
            var baseName:String = getName(asset.url, name, false);
            var fullName:String = getName(asset.url, name, true);

            if (json.ATLAS && json.meta)
            {
                helper.addPostProcessor(function(assets:AssetManager):void
                {
                    var texture:Texture = assets.getTexture(baseName);
                    assets.addAsset(baseName, new JsonTextureAtlas(texture, json));
                }, 100);
            }
            else if ((json.ANIMATION && json.SYMBOL_DICTIONARY) || (json.AN && json.SD))
            {
                helper.addPostProcessor(function(assets:AssetManager):void
                {
                    assets.addAsset(baseName, new AnimationAtlas(json,
                        assets.getTextureAtlas(baseName)), AnimationAtlas.ASSET_TYPE);
                });
            }

            onComplete(fullName, json);
        }
    }

    internal static function getName(url:String, stdName:String, addSuffix:Boolean):String
    {
        var separator:String = "/";

        // embedded classes are stripped of the suffix here
        if (url == null)
        {
            if (addSuffix) return stdName; // should already include suffix
            else
            {
                stdName = stdName.replace(AnimationAtlasFactory.ANIMATION_SUFFIX, "");
                stdName = stdName.replace(AnimationAtlasFactory.SPRITEMAP_SUFFIX, "");
            }
        }

        if ((stdName == "Animation" || stdName.match(/spritemap\d*/)) && url.indexOf(separator) != -1)
        {
            var elements:Array = url.split(separator);
            var folderName:String = elements[elements.length - 2];
            var suffix:String = stdName == "Animation" ?
                AnimationAtlasFactory.ANIMATION_SUFFIX : AnimationAtlasFactory.SPRITEMAP_SUFFIX;

            if (addSuffix) return folderName + suffix;
            else return folderName;
        }

        return stdName;
    }
}

