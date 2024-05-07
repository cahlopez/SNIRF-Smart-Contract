// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract SNIRF is ERC20, ERC20Permit, Ownable {
    address public marketingWallet;
    address public liquidityWallet;
    address public developmentWallet;
    address public constant burnAddress = address(0xdead);

    bool public tradingEnabled;
    bool public swappingEnabled;

    uint256 public buyTotalFees;
    uint256 private _buyMarketingFee;
    uint256 private _buyDevelopmentFee;
    uint256 private _buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 private _sellMarketingFee;
    uint256 private _sellDevelopmentFee;
    uint256 private _sellLiquidityFee;

    uint256 private _tokensForMarketing;
    uint256 private _tokensForDevelopment;
    uint256 private _tokensForLiquidity;
    uint256 private _previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTransaction;
    mapping(address => bool) private _isNerd;

    event ExcludeFromLimits(address indexed account, bool isExcluded);
    event ExcludeFromFees(address indexed account, bool isExcluded);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event developmentWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event liquidityWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event SwapAndLiquify(uint256 tokensSwapped , uint256 ethReceived, uint256 tokensIntoLiquidity);

    event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);

    constructor(address[] memory _nerds) ERC20("Since Birf", "SNIRF") ERC20Permit("SNIRF") Ownable(msg.sender) {
        uint256 totalSupply = 1000000000;

        uint256 liquidityPercent = 60;
        uint256 airdropPercent = 15;
        uint256 presalePercent = 5;

        address teamMultisigWallet = 0xF9E055020F1716a2398Fe71ceb3522D051dAE685;

        _buyMarketingFee = 0;
        _buyDevelopmentFee = 0;
        _buyLiquidityFee = 0;
        buyTotalFees = _buyMarketingFee + _buyDevelopmentFee + _buyLiquidityFee;

        _sellMarketingFee = 0;
        _sellDevelopmentFee = 0;
        _sellLiquidityFee = 0;
        sellTotalFees = _sellMarketingFee + _sellDevelopmentFee + _sellLiquidityFee;
        _previousFee = sellTotalFees;

        marketingWallet = teamMultisigWallet;
        developmentWallet = teamMultisigWallet;
        liquidityWallet = teamMultisigWallet;

        // excludeFromFees(owner(), true);
        // excludeFromFees(address(this), true);
        // excludeFromFees(burnAddress, true);
        // excludeFromFees(teamMultisigWallet, true);

        // excludeFromMaxTransaction(owner(), true);
        // excludeFromMaxTransaction(address(this), true);
        // excludeFromMaxTransaction(burnAddress, true);
        // excludeFromMaxTransaction(address(uniswapV2Router), true);
        // excludeFromMaxTransaction(teamMultisigWallet, true);

        _mint(address(this), (totalSupply / 100) * (liquidityPercent + airdropPercent + presalePercent));
        _mint(teamMultisigWallet, (totalSupply / 100) * 20);

        setNerd(_nerds, true);
    }
    
    receive() external payable {
        //Presale code
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function addLiquidity() public onlyOwner {
        //Add Liquidity Code
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already active.");
        tradingEnabled = true;
        swappingEnabled = true;
    }

    function toggleSwapping() public onlyOwner {
        swappingEnabled = !swappingEnabled;
    }

    function setBrett(address[] memory _nerds, bool set) internal {
        for(uint256 i = 0; i < _nerds.length; i++){
            _isNerd[_nerds[i]] = set;
        }
    }

    function excludeFromMaxTransaction(address account, bool value)
        public
        onlyOwner
    {
        _isExcludedFromMaxTransaction[account] = value;
        emit ExcludeFromLimits(account, value);
    }

    function bulkExcludeFromMaxTransaction(
        address[] calldata accounts,
        bool value
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromMaxTransaction[accounts[i]] = value;
            emit ExcludeFromLimits(accounts[i], value);
        }
    }

    function excludeFromFees(address account, bool value) public onlyOwner {
        _isExcludedFromFees[account] = value;
        emit ExcludeFromFees(account, value);
    }

    function bulkExcludeFromFees(address[] calldata accounts, bool value) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = value;
            emit ExcludeFromFees(accounts[i], value);
        }
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        bool success;
        if (tkn == address(0))
            (success, ) = address(msg.sender).call{
                value: address(this).balance
            }("");
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

    function isExcludedFromMaxTransaction(address account) public view returns (bool) {
        return _isExcludedFromMaxTransaction[account];
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
}
