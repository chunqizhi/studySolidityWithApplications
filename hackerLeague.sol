// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/ERC20.sol";


//用户推荐关系、算力购买、HE-3 代币释放和用户收益提取记录为去中心化
contract HackerLeague {
    address public owner;
    // 用户
    struct user {
        address superior;
        uint256 hashRate;
        bool isUser;
        buyInfo[] buyInfos;
    }
    mapping(address => user) public users;

    // 记录用户算力购买情况
    struct buyInfo {
        uint256 timestamp;
        uint256 hashRate;
    }
    //    mapping(address => buyInfo[]) buyInfos;

    // 用户算力购买情况事件
    event LogBuyHashRate(address owner, uint hashRate, address superior);
    // 用户收益提取记录事件
    event LogWithdraw(address owner, uint reward);

    constructor() public {
        //
        owner = msg.sender;
    }

    // 函数修改器，只有 owner 满足条件
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    /**
     * 用户购买算力
     * 需要该用户拥有 HE-1 或者 HE-3 代币
     *
     * Requirements:
     *
     * - `_token` HE-1 或者 HE-3 的合约地址
     * - `_tokenAmount` 使用 token 数量购买算力
     * - `_price` token 与 usdt 对应的价格，考虑小数点，需要协定 1 = 10000，0.03 = 300
     * - `_superior` 直接上级
     */
    function buyHashRate(ERC20 _token,uint _amount, uint _price, address _superior) public {
        require(_superior != address(0), "Superior should not be 0");
        // 判断上级是否是 user 或 owner，如果都不是，抛出错误
        if (!(users[_superior].isUser || _superior == owner)) {
            require(users[_superior].isUser, "Superior should be a user or owner");
        }

        // 是否拥有 _amount 数量的 _token 代币
        require(
            _token.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
        bool sent = _token.transferFrom(msg.sender, owner, _amount);
        require(sent, "Token transfer failed");

        // 计算_amount 等于多少 usdt
        uint usdt = _amount * _price / 10000;
        // 10 USDT = 1T
        // 计算当前能买多少算力
        uint hashRate = usdt / 10;
        // 单次购买不的少于 1T 算力
        require(hashRate >= 1, "Need buy 1T least");

        if (users[msg.sender].isUser) {
            // 再次购买，不改变直接上级，直接更新算力
            users[msg.sender].hashRate += hashRate;
        } else {
            // 第一次购买算力，更新上级和算力
            users[msg.sender].superior = _superior;
            users[msg.sender].hashRate = hashRate;
        }

        // 保存购买信息记录
        users[msg.sender].buyInfos.push(buyInfo({timestamp:block.timestamp,hashRate: hashRate}));

        // 触发事件
        emit LogBuyHashRate(msg.sender, hashRate, _superior);
    }

    /**
     * 官方触发用户的提币申请
     *
     * Requirements:
     *
     * - `_token` HE-3 的合约地址
     * - `_userAddress` 用户地址
     * - `_amount` HE-3 token 数量（手续费需用户支付，后端已经扣除等价的 HE-3）
     */
    function withdraw(ERC20 _token, address _userAddress, uint _amount) public onlyOwner {
        // 只能 owner 来调用
        // 保证 owner 地址允许该合约地址可以花费的 HE-3 token 大于等于 _amount
        require(
            _token.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );

        bool sent = _token.transferFrom(msg.sender, _userAddress, _amount);
        require(sent, "Token transfer failed");

        // 触发事件
        emit LogWithdraw(_userAddress, _amount);
    }

    /**
      * 获取用户信息
      *
      * Requirements:
      *
      * - `_userAddress` 用户地址
      */
    // 需要引入下面才能支持返回 user
    // pragma experimental ABIEncoderV2
    function userInfo(address _userAddress) public view returns (user memory) {
        return users[_userAddress];
    }

    /**
     * 获取用户上级
     *
     * Requirements:
     *
     * - `_userAddress` 用户地址
     */
    function userSuperior(address _userAddress) public view returns (address) {
        return users[_userAddress].superior;
    }

    /**
     * 获取用户算力
     *
     * Requirements:
     *
     * - `_userAddress` 用户地址
     */
    function userHashRate(address _userAddress) public view returns (uint) {
        return users[_userAddress].hashRate;
    }

    /**
     * 判断该地址是否为用户
     *
     * Requirements:
     *
     * - `_userAddress` 用户地址
     */
    function isUser(address _userAddress) public view returns (bool) {
        return users[_userAddress].isUser;
    }

    /**
     * 获取用户的购买历史数据
     *
     * Requirements:
     *
     * - `_userAddress` 用户地址
     */
    function getBuyInfo(address _userAddress) public view returns (buyInfo[] memory) {
        return users[_userAddress].buyInfos;
    }
}