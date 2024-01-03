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
    address internal _topHatHolder = makeAddr("topHatHolder");

    uint256 internal _facilitatorHatId;

    function __HatsSetupLive() internal {
        _hats_ = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);
        _createHats();
    }

    function hats() public view returns (IHats) {
        return _hats_;
    }

    function topHatHolder() public view returns (address) {
        return _topHatHolder;
    }

    function topHatId() public view returns (uint256) {
        return _topHatId;
    }

    function _createHats() internal {
        _topHatId = hats().mintTopHat(topHatHolder(), "Top Hat", "https://wwww/tophat.com/");
    }
}
