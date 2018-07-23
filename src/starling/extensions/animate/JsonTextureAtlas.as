package starling.extensions.animate
{
    import flash.geom.Rectangle;

    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import starling.utils.Pool;

    /** A TextureAtlas that supports the JSON file format used by Adobe Animate's 'Texture Atlas'
     *  export. */
    public class JsonTextureAtlas extends TextureAtlas
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
}
