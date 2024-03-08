// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IBond {
    function redeem( address _recipient, uint _id, bool _stake ) external returns ( uint );
    function pendingPayoutFor( address _depositor,uint _id, bool _stake ) external returns ( uint );
}

contract RedeemHelper is Ownable {

    address[] public bonds;

    function redeemAll( address _recipient,uint[] memory _ids, bool _stake ,bool _invite) external {
        for( uint i = 0; i < bonds.length; i++ ) {
            if ( bonds[i] != address(0) ) {
                for (uint index = 0; index < _ids.length; index++) {
                    if ( IBond( bonds[i] ).pendingPayoutFor( _recipient, _ids[index], _invite) > 0 ) {
                        IBond( bonds[i] ).redeem( _recipient, _ids[index], _stake );
                    }
                }
            }
        }
    }

    function addBondContract( address _bond ) external onlyPolicy() {
        require( _bond != address(0) );
        bonds.push( _bond );
    }

    function removeBondContract( uint _index ) external onlyPolicy() {
        bonds[ _index ] = address(0);
    }
}
