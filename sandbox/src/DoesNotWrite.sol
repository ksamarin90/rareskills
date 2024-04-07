// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DoesNotWrite {
    struct Foo {
        uint256 bar;
    }

    Foo[] public myArray;

    function getElement(uint256 index) external view returns (Foo memory) {
        return myArray[index];
    }

    function addElement(Foo calldata foo) external {
        myArray.push(foo);
    }

    function moveToSlot0() external {
        Foo storage foo = myArray[0];
        foo.bar = myArray[1].bar; // myArray[0] is unchanged
            // we do this to make the function a state
            // changing operation
            // and silence the compiler warning
            // myArray[1] = Foo({bar: 100});
    }
}
