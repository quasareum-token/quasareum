// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract QuasareumToken {
    string public name = "Quasareum";
    string public symbol = "QSRM";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public constant TARGET = 992199;
    uint256 public constant MINE_DELAY = 900;

    mapping(address => mapping(bytes32 => bool)) public usedSolutions;
    mapping(address => uint256) public lastMineTime;

    address public owner;
    bool public paused;

    uint256 public pricePerToken;  
    bool public marketPaused;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mined(address indexed miner, string solution);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event MarketPaused(address indexed by);
    event MarketUnpaused(address indexed by);
    event Bought(address indexed buyer, uint256 ethSpent, uint256 tokensReceived);
    event Sold(address indexed seller, uint256 tokensSold, uint256 ethReceived);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    modifier whenMarketNotPaused() {
        require(!marketPaused, "market paused");
        _;
    }

    constructor(uint256 initialMarketTokens, uint256 initialPrice) {
        owner = msg.sender;
        pricePerToken = initialPrice;

        totalSupply = initialMarketTokens;
        balanceOf[address(this)] = initialMarketTokens;

        emit Transfer(address(0), address(this), initialMarketTokens);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function pauseMarket() external onlyOwner {
        marketPaused = true;
        emit MarketPaused(msg.sender);
    }

    function unpauseMarket() external onlyOwner {
        marketPaused = false;
        emit MarketUnpaused(msg.sender);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        pricePerToken = newPrice;
    }

    function _transfer(address from, address to, uint256 value) internal whenNotPaused {
        require(to != address(0), "transfer to zero");
        require(balanceOf[from] >= value, "balance too low");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external whenNotPaused returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external whenNotPaused returns (bool) {
        require(allowance[from][msg.sender] >= value, "not allowed");
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function mine(string calldata solution) external whenNotPaused returns (bool) {
        require(block.timestamp >= lastMineTime[msg.sender] + MINE_DELAY, "Wait 15 minutes");

        bytes32 key = keccak256(abi.encodePacked(solution));
        require(!usedSolutions[msg.sender][key], "already used");

        uint256 h = quasareumHash(msg.sender, solution);
        lastMineTime[msg.sender] = block.timestamp;

        if (h == TARGET) {
            usedSolutions[msg.sender][key] = true;
            balanceOf[msg.sender] += 1 ether;
            totalSupply += 1 ether;

            emit Transfer(address(0), msg.sender, 1 ether);
            emit Mined(msg.sender, solution);
            return true;
        }
        return false;
    }

    function getBuyAmount(uint256 ethAmount) public view returns (uint256) {
        if (ethAmount == 0) return 0;
        uint256 tokensAvailable = balanceOf[address(this)];
        uint256 tokens = (ethAmount * (10 ** uint256(decimals))) / pricePerToken;
        if (tokens > tokensAvailable) tokens = tokensAvailable;
        return tokens;
    }

    function getSellAmount(uint256 tokenAmount) public view returns (uint256) {
        if (tokenAmount == 0) return 0;
        uint256 ethAmount = (tokenAmount * pricePerToken) / (10 ** uint256(decimals));
        uint256 maxPayout = (address(this).balance * 5) / 100;
        if (ethAmount > maxPayout) ethAmount = maxPayout;
        return ethAmount;
    }

    function buy(uint256 expectedTokens) external payable whenNotPaused whenMarketNotPaused {
        require(balanceOf[address(this)] > 0, "buy disabled: no tokens");
        require(msg.value > 0, "no ETH sent");

        uint256 tokensToBuy = getBuyAmount(msg.value);
        require(tokensToBuy > 0, "not enough ETH for 1 token");

        uint256 minOut = expectedTokens * 50 / 100;
        uint256 maxOut = expectedTokens * 150 / 100;
        require(tokensToBuy >= minOut && tokensToBuy <= maxOut, "slippage too high");

        balanceOf[address(this)] -= tokensToBuy;
        balanceOf[msg.sender] += tokensToBuy;

        emit Transfer(address(this), msg.sender, tokensToBuy);
        emit Bought(msg.sender, msg.value, tokensToBuy);
    }

    function sell(uint256 amount, uint256 expectedEth) external whenNotPaused whenMarketNotPaused {
        require(address(this).balance > 100 wei, "sell disabled: low ETH reserve");
        require(amount > 0, "amount = 0");
        require(balanceOf[msg.sender] >= amount, "not enough tokens");

        uint256 ethAmount = getSellAmount(amount);
        require(ethAmount > 0, "payout too small");

        uint256 minOut = expectedEth * 50 / 100;
        uint256 maxOut = expectedEth * 150 / 100;
        require(ethAmount >= minOut && ethAmount <= maxOut, "slippage too high");

        balanceOf[msg.sender] -= amount;
        balanceOf[address(this)] += amount;

        emit Transfer(msg.sender, address(this), amount);

        payable(msg.sender).transfer(ethAmount);
        emit Sold(msg.sender, amount, ethAmount);
    }

    function quasareumHash(address user, string memory s) public pure returns (uint256) {
        bytes memory data = abi.encodePacked(user, s);
        uint64 h = 0xcbf29ce484222325;
        for (uint256 i = 0; i < data.length; i++) {
            h ^= uint8(data[i]);
            h = uint64(uint256(h) * 0x100000001b3 & 0xFFFFFFFFFFFFFFFF);
        }
        h ^= uint64(data.length);
        h &= 0xFFFFFFFFFFFFFFFF;
        h ^= (h >> 30);
        h = uint64(uint256(h) * 0xbf58476d1ce4e5b9 & 0xFFFFFFFFFFFFFFFF);
        h ^= (h >> 27);
        h = uint64(uint256(h) * 0x94d049bb133111eb & 0xFFFFFFFFFFFFFFFF);
        h ^= (h >> 31);
        uint256 M = 1_000_000;
        uint256 result = (uint256(h) * M) >> 64;
        return result + 1;
    }
}