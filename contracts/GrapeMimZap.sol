// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 * Swap Sicle
 * MIT License; modified from PancakeBunny
 *
 */

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISiclePair.sol";
import "./interfaces/ISicleRouter02.sol";
import "./interfaces/IWAVAX.sol";

contract GrapeMimZap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant GRAPE = 0x5541D83EFaD1f281571B343977648B75d95cdAC2;
    address public constant MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public constant GRAPE_MIM_LP = 0x9076C15D7b2297723ecEAC17419D506AE320CbF1;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    ISicleRouter02 private ROUTER;

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notLP;
    address[] public tokens;


    /* ========== CONSTRUCTOR ========== */

    constructor (address _router) {
        require(owner() != address(0), "ZapETH: owner must be set");

        ROUTER = ISicleRouter02(_router);
        setNotLP(GRAPE);
        setNotLP(MIM);
        setNotLP(WAVAX);
    }

    receive() external payable {}

    /* ========== External Functions ========== */

    function zapInToken(
        address _from,
        uint256 amount
    ) external {
        require(_from == GRAPE || _from == MIM, 'Unsupported zap token');
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        ISiclePair pair = ISiclePair(GRAPE_MIM_LP);
        address token0 = pair.token0();
        address token1 = pair.token1();
        // swap half amount for other
        address other = _from == token0 ? token1 : token0;
        _approveTokenIfNeeded(other);
        uint256 sellAmount = amount.div(2);
        uint256 otherAmount = _swap(_from, sellAmount, other, address(this));
        ROUTER.addLiquidity(
            _from,
            other,
            amount.sub(sellAmount),
            otherAmount,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }

    function zapOut(uint256 amount) external {
        IERC20(GRAPE_MIM_LP).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(GRAPE_MIM_LP);

        ISiclePair pair = ISiclePair(GRAPE_MIM_LP);
        address token0 = pair.token0();
        address token1 = pair.token1();
        ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(ROUTER)) == 0) {
            IERC20(token).safeApprove(address(ROUTER), ~uint256(0));
        }
    }

    function _swap(
        address _from,
        uint256 amount,
        address _to,
        address receiver
    ) private returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = _from;
        path[1] = _to;

        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForAVAX(
        address token,
        uint256 amount,
        address receiver
    ) private returns (uint256) {
        address[] memory path;
        
        path = new address[](2);
        path[0] = token;
        path[1] = WAVAX;

        uint256[] memory amounts = ROUTER.swapExactTokensForETH(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setNotLP(address token) public onlyOwner {
        bool needPush = notLP[token] == false;
        notLP[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function sweep() external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                if (token == WAVAX) {
                    IWAVAX(token).withdraw(amount);
                } else {
                    _swapTokenForAVAX(token, amount, owner());
                }
            }
        }

        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
}