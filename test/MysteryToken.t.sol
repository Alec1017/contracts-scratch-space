// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC1155} from "openzeppelin-contracts/interfaces/IERC1155.sol";
import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

contract MysteryTokenTest is Test {
    uint256 public polygonFork;

    address public immutable mysteryToken =
        0xA2a13cE1824F3916fC84C65e559391fc6674e6e8;

    bytes4 private constant ERC721_RECEIVED_VALUE = 0x150b7a02;
    bytes4 private constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC721_RECEIVED_VALUE;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_RECEIVED_VALUE;
    }

    function setUp() public {
        // Set up the polygon fork
        polygonFork = vm.createFork(vm.rpcUrl("polygon"));
    }

    modifier forkPolygonMainnet() {
        // create the polygon fork
        vm.selectFork(polygonFork);
        _;
    }

    function testIERC165SupportForERC721() public forkPolygonMainnet {
        // Assert that there is code at this address, indicating a successful fork
        assertGt(mysteryToken.code.length, 0);

        // Check if the contract supports IERC165 for ERC721
        (bool success, bytes memory data) = mysteryToken.call(
            abi.encodeWithSelector(
                IERC165.supportsInterface.selector,
                0x80ac58cd
            )
        );

        if (success) {
            console.log("SUCCESS: Contract supports ERC721 interface");
        } else {
            console.log("FAIL: IERC165 call failed for ERC721");
        }

        console.logBytes(data);
    }

    function testIERC165SupportForERC1155() public forkPolygonMainnet {
        // Assert that there is code at this address, indicating a successful fork
        assertGt(mysteryToken.code.length, 0);

        // Check if the contract supports IERC165 for ERC1155
        (bool success, bytes memory data) = mysteryToken.call(
            abi.encodeWithSelector(
                IERC165.supportsInterface.selector,
                0xd9b67a26
            )
        );

        if (success) {
            console.log("SUCCESS: Contract supports ERC1155 interface");
        } else {
            console.log("FAIL: IERC165 call failed for ERC1155");
        }

        console.logBytes(data);
    }

    function testERC721Compatibility() public forkPolygonMainnet {
        // The token id
        uint256 tokenId = 16501;

        // The current owner of the token
        address owner;
        (bool ownerOk, bytes memory result) = mysteryToken.call(
            abi.encodeWithSelector(IERC721.ownerOf.selector, tokenId)
        );

        if (ownerOk) {
            owner = abi.decode(result, (address));
        } else {
            console.log("FAIL: Token is not ERC721-compatible");
            return;
        }

        // Send the token to address(this)
        vm.prank(owner);
        (bool ok, ) = mysteryToken.call(
            abi.encodeWithSelector(
                bytes4(keccak256("safeTransferFrom(address,address,uint256)")),
                owner,
                address(this),
                tokenId
            )
        );

        if (ok) {
            // Assert that address(this) owns the token
            assertEq(IERC721(mysteryToken).ownerOf(tokenId), address(this));

            console.log("SUCCESS: Token is ERC721-compatible");
        } else {
            console.log("FAIL: Token is not ERC721-compatible");
        }
    }

    function testERC1155Compatibility() public forkPolygonMainnet {
        // The token id
        uint256 tokenId = 16501;
        address owner = 0x654d8b153A10f8231Bc9954500aFa7aeD7A76851;

        // The current balance of the token
        (bool balanceOk, bytes memory result) = mysteryToken.call(
            abi.encodeWithSelector(IERC1155.balanceOf.selector, owner, tokenId)
        );

        if (balanceOk) {
            owner = abi.decode(result, (address));
        } else {
            console.log("FAIL: Token is not ERC1155-compatible");
            return;
        }

        // Send the token to address(this)
        vm.prank(owner);
        (bool ok, ) = mysteryToken.call(
            abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                owner,
                address(this),
                tokenId,
                uint256(1),
                ""
            )
        );

        if (ok) {
            // Assert that address(this) owns the token
            assertEq(
                IERC1155(mysteryToken).balanceOf(address(this), tokenId),
                1
            );

            console.log("SUCCESS: Token is ERC1155-compatible");
        } else {
            console.log("FAIL: Token is not ERC1155-compatible");
        }
    }
}
