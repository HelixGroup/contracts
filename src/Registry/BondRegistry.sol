//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "src/Interface/iBond.sol";
import "src/Interface/iName.sol";
import "src/Interface/iHelix2.sol";
import "src/Interface/iERC721.sol";
import "src/Utils/LibString.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Bond Base
 */
abstract contract Helix2Bonds {
    using LibString for bytes32[];
    using LibString for bytes32;
    using LibString for address[];
    using LibString for address;
    using LibString for string[];
    using LibString for string;

    iHELIX2 public HELIX2 = iHELIX2(address(0x0));
    iNAME public NAMES = iNAME(HELIX2.getRegistry()[1]);

    /// @dev : Helix2 Bond events
    event NewDev(address Dev, address newDev);
    event NewBond(bytes32 indexed bondhash, bytes32 cation);
    event Hooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Rehooked(bytes32 indexed bondhash, address config, uint8 rule);
    event Unhooked(bytes32 indexed bondhash, address config);
    event UnhookedAll(bytes32 indexed bondhash);
    event NewCation(bytes32 indexed bondhash, bytes32 cation);
    event NewAnion(bytes32 indexed bondhash, bytes32 anion);
    event NewAlias(bytes32 indexed bondhash, bytes32 _alias);
    event NewController(bytes32 indexed bondhash, address controller);
    event NewExpiry(bytes32 indexed bondhash, uint expiry);
    event NewRecord(bytes32 indexed bondhash, address resolver);
    event NewSecureFlag(bytes32 indexed bondhash, bool secure);
    event NewResolver(bytes32 indexed bondhash, address resolver);
    event ApprovalForAll(address indexed cation, address indexed operator, bool approved);

    /// Dev
    address public Dev;

    /// @dev : Bond roothash
    bytes32 public roothash = HELIX2.getRoothash()[1];
    uint256 public basePrice = HELIX2.getPrices()[1]; 

    /// @dev : Helix2 Bond struct
    struct Bond {
        address[] _hooks;                     /// Hooks
        mapping(address => uint8) _rules;     /// Rules for Hooks
        bytes32 _cation;                      /// Source of Bond (= Owner)
        bytes32 _anion;                       /// Target of Bond
        bytes32 _alias;                       /// Hash of Bond
        address _resolver;                    /// Resolver of Bond
        address _controller;                  /// Controller of Bond
        bool _secure;                         /// Mutuality Flag
        uint _expiry;                         /// Expiry of Bond
    }
    mapping (bytes32 => Bond) public Bonds;
    mapping (address => mapping(address => bool)) Operators;

    /**
    * @dev Initialise a new HELIX2 Bonds Registry
    * @notice : grants ownership of '0x0' to contract
    */
    constructor() {
        /// give ownership of '0x0' and <roothash> to Dev
        Bonds[0x0]._cation = roothash;
        Bonds[roothash]._cation = roothash;
        Dev = msg.sender;
    }

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        require(
            msg.sender == Dev, 
            "NOT_DEV"
        );
        _;
    }

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit NewDev(Dev, newDev);
        Dev = newDev;
    }

    /// @dev : Modifier to allow only Controller
    modifier onlyController(bytes32 bondhash) {
        require(
            block.timestamp < Bonds[bondhash]._expiry, 
            'BOND_EXPIRED'
        ); // expiry check
        require(
            msg.sender == Bonds[bondhash]._controller, 
            'NOT_CONTROLLER'
        );
        _;
    }

    /// @dev : Modifier to allow Cation or Controller
    modifier isCationOrController(bytes32 bondhash) {
        require(
            block.timestamp < Bonds[bondhash]._expiry, 
            'BOND_EXPIRED'
        ); // expiry check
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender] || msg.sender == Bonds[bondhash]._controller, 
            "NOT_OWNER_OR_CONTROLLER"
        );
        _;
    }

    /**
     * @dev : verify bond is not expired
     * @param bondhash : label of bond
     */
    modifier isNotExpired(bytes32 bondhash) {
        require(
            block.timestamp < Bonds[bondhash]._expiry, 
            'BOND_EXPIRED'
        ); // expiry check
        _;
    }

    /**
     * @dev : check if the bond is not duplicate
     * @param bondhash : hash of bond
     * @param newAnion : hash of new anion
     */
    function isNotDuplicateAnion(
        bytes32 bondhash, 
        bytes32 newAnion
    ) public view 
        returns (bool) 
    {
        bytes32 _anion =  Bonds[bondhash]._anion;
        return _anion != newAnion;
    }

    /**
     * @dev : check if new config is a duplicate
     * @param bondhash : hash of bond
     * @param config : config to check
     */
    function isNotDuplicateHook(
        bytes32 bondhash,  
        address config 
    ) public view 
        returns (bool) 
    {
        return !config.existsIn(Bonds[bondhash]._hooks);
    }

    /**
     * @dev : verify ownership of bond
     * @param bondhash : hash of bond
     */
    modifier onlyCation(bytes32 bondhash) {
        require(
            block.timestamp < Bonds[bondhash]._expiry, 
            'BOND_EXPIRED'
        ); // expiry check
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        require(
            _cation == msg.sender || Operators[_cation][msg.sender], 
            "NOT_OWNER"
        );
        _;
    }

    /**
     * @dev : set cation of a bond
     * @param bondhash : hash of bond
     * @param _cation : new cation
     */
    function setCation(bytes32 bondhash, bytes32 _cation) external onlyCation(bondhash) {
        Bonds[bondhash]._cation = _cation;
        emit NewCation(bondhash, _cation);
    }

    /**
     * @dev : set controller of a bond
     * @param bondhash : hash of bond
     * @param _controller : new controller
     */
    function setController(bytes32 bondhash, address _controller) external isCationOrController(bondhash) {
        Bonds[bondhash]._controller = _controller;
        emit NewController(bondhash, _controller);
    }

    /**
     * @dev : set new anion of a bond
     * @param bondhash : hash of anion
     * @param _anion : address of anion
     */
    function setAnion(bytes32 bondhash, bytes32 _anion) external isCationOrController(bondhash) {
        Bonds[bondhash]._anion = _anion;
        emit NewAnion(bondhash, _anion);
    }

    /**
     * @dev : set new alias for bond
     * @param bondhash : hash of bond
     * @param _alias : bash of alias
     */
    function setAlias(bytes32 bondhash, bytes32 _alias) external isCationOrController(bondhash) {
        Bonds[bondhash]._alias = _alias;
        emit NewAlias(bondhash, _alias);
    }

    /**
     * @dev : set new mutuality flag for bond
     * @param bondhash : hash of bond
     * @param _secure : bool
     */
    function setSecure(bytes32 bondhash, bool _secure) external isCationOrController(bondhash) {
        Bonds[bondhash]._secure = _secure;
        emit NewSecureFlag(bondhash, _secure);
    }

    /**
     * @dev : set resolver for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new resolver
     */
    function setResolver(bytes32 bondhash, address _resolver) external isCationOrController(bondhash) {
        Bonds[bondhash]._resolver = _resolver;
        emit NewResolver(bondhash, _resolver);
    }

    /**
     * @dev : set expiry for a bond
     * @param bondhash : hash of bond
     * @param _expiry : new expiry
     */
    function setExpiry(bytes32 bondhash, uint _expiry) external payable isCationOrController(bondhash) {
        require(
            _expiry > Bonds[bondhash]._expiry,
            "BAD_EXPIRY"
        );
        uint newDuration = _expiry - Bonds[bondhash]._expiry;
        require(
            msg.value >= newDuration * basePrice,
            'INSUFFICIENT_ETHER'
        );
        Bonds[bondhash]._expiry = _expiry;
        emit NewExpiry(bondhash, _expiry);
    }

    /**
     * @dev : set record for a bond
     * @param bondhash : hash of bond
     * @param _resolver : new record
     */
    function setRecord(
        bytes32 bondhash, 
        address _resolver
    ) external 
        isCationOrController(bondhash) 
    {
        Bonds[bondhash]._resolver = _resolver;
        emit NewRecord(bondhash, _resolver);
    }

    /**
     * @dev adds a hook with rule
     * @param bondhash : hash of the bond
     * @param rule : rule for the hook
     * @param config : address of config contract
     */
    function hook( 
        bytes32 bondhash, 
        uint8 rule,
        address config
    ) external 
        onlyCation(bondhash)
    {
        require(
            isNotDuplicateHook(bondhash, config),
            "HOOK_EXISTS"
        );
        Bonds[bondhash]._hooks.push(config);
        Bonds[bondhash]._rules[config] = rule;
        emit Hooked(bondhash, config, rule);
    }

    /**
     * @dev rehooks a hook to a new rule
     * @param bondhash : hash of the bond
     * @param rule : rule for the hook
     * @param config : address of config contract
     */
    function rehook( 
        bytes32 bondhash, 
        uint8 rule,
        address config
    ) external 
        onlyCation(bondhash)
    {
        require(
            Bonds[bondhash]._rules[config] != rule,
            'RULE_EXISTS'
        );
        Bonds[bondhash]._rules[config] = rule;
        emit Rehooked(bondhash, config, rule);
    }

    /**
     * @dev removes a hook in a bond
     * @param bondhash : hash of the bond
     * @param config : contract address of config
     */
    function unhook( 
        bytes32 bondhash, 
        address config
    ) external 
        onlyCation(bondhash)
    {
        address[] memory _hooks = Bonds[bondhash]._hooks;
        if (config.existsIn(_hooks)) {
            uint index = config.findIn(_hooks);
            if (index == uint(0)) {
                emit Unhooked(bondhash, address(0));
            } else {
                Bonds[bondhash]._rules[config] = uint8(0);
                emit Unhooked(bondhash, config);
                delete Bonds[bondhash]._hooks[index];
            }
        } else {
            emit Unhooked(bondhash, address(0));
        }
    }

    /**
     * @dev removes all hooks in a bond
     * @param bondhash : hash of the bond
     */
    function unhookAll( 
        bytes32 bondhash
    ) external 
        onlyCation(bondhash)
    {
        address[] memory _hooks = Bonds[bondhash]._hooks;
        for (uint i = 0; i < _hooks.length; i++) {
            Bonds[bondhash]._rules[_hooks[i]] = uint8(0);
            emit Unhooked(bondhash, _hooks[i]);
        }
        delete Bonds[bondhash]._hooks;
        emit UnhookedAll(bondhash);
        Bonds[bondhash]._hooks.push(address(0));
    }

    /**
     * @dev : set operator for a bond
     * @param operator : new operator
     * @param approved : state to set
     */
    function setApprovalForAll(address operator, bool approved) external {
        Operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev return cation of a bond
     * @param bondhash : hash of bond to query
     * @return hash of cation
     */
    function cation(bytes32 bondhash) public view isNotExpired(bondhash) returns (bytes32) {
        bytes32 __cation = Bonds[bondhash]._cation;
        address _cation = NAMES.owner(__cation);
        if (_cation == address(this)) {
            return roothash;
        }
        return __cation;
    }

    /**
     * @dev return controller of a bond
     * @param bondhash : hash of bond to query
     * @return address of controller
     */
    function controller(bytes32 bondhash) public view isNotExpired(bondhash) returns (address) {
        address _controller = Bonds[bondhash]._controller;
        return _controller;
    }

    /**
     * @dev return anion of a bond
     * @param bondhash : hash of bond to query
     * @return hash of anion
     */
    function anion(bytes32 bondhash) public view isNotExpired(bondhash) returns (bytes32) {
        bytes32 _anion = Bonds[bondhash]._anion;
        return _anion;
    }

    /**
     * @dev shows mutuality state of a bond
     * @param bondhash : hash of bond to query
     * @return mutuality state of the bond
     */
    function secure(bytes32 bondhash) public view isNotExpired(bondhash) returns (bool) {
        bool _secure = Bonds[bondhash]._secure;
        return _secure;
    }

    /**
     * @dev return hooks of a bond
     * @param bondhash : hash of bond to query
     * @return tuple of (hooks, rules)
     */
    function hooks(bytes32 bondhash) public view isNotExpired(bondhash) returns (address[] memory, uint8[] memory) {
        address[] memory _hooks = Bonds[bondhash]._hooks;
        uint8[] memory _rules = new uint8[](_hooks.length);
        for (uint i = 0; i < _hooks.length; i++) {
            _rules[i] = Bonds[bondhash]._rules[_hooks[i]];
        }
        return (_hooks, _rules);
    }

    /**
     * @dev return expiry of a bond
     * @param bondhash : hash of bond to query
     * @return expiry
     */
    function expiry(bytes32 bondhash) public view returns (uint) {
        uint _expiry = Bonds[bondhash]._expiry;
        return _expiry;
    }   

    /**
     * @dev return resolver of a bond
     * @param bondhash : hash of bond to query
     * @return address of resolver
     */
    function resolver(bytes32 bondhash) public view isNotExpired(bondhash) returns (address) {
        address _resolver = Bonds[bondhash]._resolver;
        return _resolver;
    }

    /**
     * @dev check if a bond is registered
     * @param bondhash : hash of bond to query
     * @return true or false
     */
    function recordExists(bytes32 bondhash) public view returns (bool) {
        return block.timestamp < Bonds[bondhash]._expiry;
    }
    
    /**
     * @dev check if an address is set as operator
     * @param _cation cation of bond to query
     * @param operator operator to check
     * @return true or false
     */
    function isApprovedForAll(bytes32 _cation, address operator) external view returns (bool) {
        address __cation = NAMES.owner(_cation);
        return Operators[__cation][operator];
    }

    /**
     * @dev : withdraw ether to Dev, anyone can trigger
     */
    function withdrawEther() external payable {
        (bool ok,) = Dev.call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     */
    function withdrawToken(address token) external payable {
        iERC20(token).transferFrom(address(this), Dev, iERC20(token).balanceOf(address(this)));
    }

}
