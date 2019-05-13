package starling.extensions.animate
{
    import starling.errors.AbstractClassError;

    internal class LoopMode
    {
        /** @private */
        public function LoopMode() { throw new AbstractClassError(); }

        public static const LOOP:String = "loop";
        public static const PLAY_ONCE:String = "playonce";
        public static const SINGLE_FRAME:String = "singleframe";

        public static function isValid(value:String):Boolean
        {
            return value == LOOP || value == PLAY_ONCE || value == SINGLE_FRAME;
        }

        public static function parse(value:String):String
        {
            switch (value)
            {
                case "LP":
                case LOOP: return LOOP;
                case "PO":
                case PLAY_ONCE: return PLAY_ONCE;
                case "SF":
                case SINGLE_FRAME: return SINGLE_FRAME;
                default: throw new ArgumentError("Invalid loop mode: " + value);
            }
        }
    }
}
