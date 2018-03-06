package starling.extensions.animate
{
    import starling.errors.AbstractClassError;

    internal class SymbolType
    {
        /** @private */
        public function SymbolType() { throw new AbstractClassError(); }

        public static const GRAPHIC:String = "graphic";
        public static const MOVIE_CLIP:String = "movieclip";
        public static const BUTTON:String = "button";

        public static function isValid(value:String):Boolean
        {
            return value == GRAPHIC || value == MOVIE_CLIP || value == BUTTON;
        }
    }
}
