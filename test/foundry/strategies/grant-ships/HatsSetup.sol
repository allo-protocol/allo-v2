// External Libraries
import "forge-std/Test.sol";
import {IHats} from "hats-protocol/Interfaces/IHats.sol";

// Internal Libraries
import {Accounts} from "../../shared/Accounts.sol";

contract HatsSetupLive is Test, Accounts {
    struct TestShipHats {
        address shipAddress;
        uint256 shipHatId;
        uint256 shipOperatorHatId;
        address[3] shipOperators;
    }

    IHats internal _hats_;

    uint256 internal _topHatId;
    uint256 internal _facilitatorHatId;

    function __HatsSetupLive() internal {
        _hats_ = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);
        _createHats();
    }

    function _createHats() internal {}

    function hats() public view returns (IHats) {
        return _hats_;
    }
}
