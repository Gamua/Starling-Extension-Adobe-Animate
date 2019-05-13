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

        public static function parse(value:String):String
        {
            switch (value)
            {
                case "G":
                case GRAPHIC: return GRAPHIC;
                case "MC":
                case MOVIE_CLIP: return MOVIE_CLIP;
                case "B":
                case BUTTON: return BUTTON;
                default: throw new ArgumentError("Invalid symbol type: " + value);
            }
        }
    }
}
