package starling.extensions.animate
{
    import starling.errors.AbstractClassError;

    public class LoopMode
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
    }
}
