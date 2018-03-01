package starling.extensions.animate
{
    import starling.assets.AssetFactoryHelper;
    import starling.assets.AssetManager;
    import starling.assets.AssetReference;
    import starling.assets.JsonFactory;
    import starling.textures.Texture;

    public class AnimateFactory extends JsonFactory
    {
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
                        var textureName:String = helper.getNameFromUrl(json.meta.image);
                        var texture:Texture = assets.getTexture(textureName);
                        assets.addAsset(name, new JsonTextureAtlas(texture, json));
                    });
                }

                onComplete(name, json);
            }
        }
    }
}
