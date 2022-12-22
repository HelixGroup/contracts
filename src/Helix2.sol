//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/// @dev : ERC Standards
import "src/ERC721.sol";

/// @dev : Helix2 Structs
import "src/Name.sol";
import "src/Bond.sol";
import "src/Molecule.sol";
import "src/Polycule.sol";

/// @dev : Helix2 Interfaces
import "src/interface/iHelix2.sol";
import "src/interface/iName.sol";
import "src/interface/iBond.sol";
import "src/interface/iMolecule.sol";
import "src/interface/iPolycule.sol";
//import "src/interface/iResolver.sol";

/// @dev : Other Interfaces
import "src/interface/iENS.sol";
import "src/interface/iERC721.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Registrar
 */
contract HELIX2 is ERC721 {

    /// @dev : initialise interfaces
    iENS public ENS;
    iNAME public NAME;
    iBOND public BOND;
    iMOLECULE public MOLECULE;
    iPOLYCULE public POLYCULE;

    mapping(bytes4 => bool) public supportsInterface;

    /// @dev : initialise registers
    ENS = iENS(ensRegistry);
    NAME = iNAME(helix2Registry[0]);
    BOND = iBOND(helix2Registry[1]);
    MOLECULE = iMOLECULE(helix2Registry[2]);
    POLYCULE = iPOLYCULE(helix2Registry[3]);

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        require(msg.sender == Dev, "NOT_DEV");
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

    /**
     * @dev : migrate all Helix2 Registers
     * @param newReg : new Registry array
     */
    function setRegistry(address[4] newReg) external onlyDev {
        emit NewRegistry(newReg);
        helix2Registry = newReg;
    }

    /**
     * @dev : replace one index of Helix2 Register
     * @param index : index to replace (starts from 0)
     * @param newReg : new Register for index
     */
    function setSubRegistry(uint256 index, address newReg) external onlyDev {
        emit NewSubRegistry(index, newReg);
        helix2Registry[index] = newReg;
    }

    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    // CORE FUNCTIONS

    /**
     * @dev registers a new name
     * @param labelhash label of name without suffix
     * @param owner owner to set for new name
     * @return hash of new name
     */
    function registerName(bytes32 labelhash, address owner) external {
        NAME.newName(bytes32 labelhash, address owner);
    }

    /**
     * @dev registers a new bond
     * @param labelhash label of bond without suffix
     * @param owner owner to set for new bond
     * @return hash of new bond
     */
    function registerBond(bytes32 labelhash, address owner) external {
        BOND.newBond(bytes32 labelhash, address owner);
    }

    /**
     * @dev registers a new molecule
     * @param labelhash label of molecule without suffix
     * @param owner owner to set for new molecule
     * @return hash of new molecule
     */
    function registerMolecule(bytes32 labelhash, address owner) external {
        MOLECULE.newMolecule(bytes32 labelhash, address owner);
    }

    /**
     * @dev registers a new polycule
     * @param labelhash label of polycule without suffix
     * @param owner owner to set for new polycule
     * @return hash of new polycule
     */
    function registerPolycule(bytes32 labelhash, address owner) external {
        POLYCULE.newPolycule(bytes32 labelhash, address owner);
    }

}
