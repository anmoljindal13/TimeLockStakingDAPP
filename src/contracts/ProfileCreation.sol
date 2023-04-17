// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "hardhat/console.sol";

/**
 * @title ProfileCreation
 * @dev A smart contract for creating and viewing user profiles.
 */
contract ProfileCreation {
    struct UserInfo {
        string name;
        string email;
        string pictureUrl;
    }

    mapping(address => UserInfo) public userInfos;

    event ProfileCreated(address indexed user, string name, string email, string pictureUrl);

    /**
    * @dev The createProfile function allows a user to create a new profile by providing a name, email, and picture URL. 
    *      The function checks that each of these fields is not empty and that the user does not already have a profile. 
    *      The user's profile information is then stored in the userInfos mapping and a ProfileCreated event is emitted.
    * @param _name Name of the user
    * @param _email Email of the user
    * @param _pictureUrl URL of the user's profile picture
    */
    function createProfile(string memory _name, string memory _email, string memory _pictureUrl) public {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        require(bytes(_pictureUrl).length > 0, "Picture URL cannot be empty");

        require(bytes(userInfos[msg.sender].name).length == 0, "Profile already exists for user!");

        userInfos[msg.sender] = UserInfo({
            name: _name,
            email: _email,
            pictureUrl: _pictureUrl
        });
        console.log("New Profile created for User : %s", _name);
        emit ProfileCreated(msg.sender, _name, _email, _pictureUrl);
    }

    /**
    * @dev The viewProfile function allows anyone to view a user's profile information by calling the function with the user's Ethereum address as an argument. 
    *      The function checks that a profile exists for the user and returns their name, email, and picture URL.
    * @return name Name of the user
    * @return email Email of the user
    * @return pictureUrl URL of the user's profile picture
    */
    function viewProfile() external view returns (string memory name, string memory email, string memory pictureUrl) {
        require(bytes(userInfos[msg.sender].name).length > 0, "Profile does not exist for the user!");
        UserInfo storage userInfo = userInfos[msg.sender];
        return (userInfo.name, userInfo.email, userInfo.pictureUrl);
    }
    
}