// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import {ImmutableSplitsDriver} from "src/ImmutableSplitsDriver.sol";
import {BeamsHub, SplitsReceiver, UserMetadata} from "src/BeamsHub.sol";
import {ManagedProxy} from "src/Managed.sol";
import {Test} from "forge-std/Test.sol";

contract ImmutableSplitsDriverTest is Test {
    BeamsHub internal beamsHub;
    ImmutableSplitsDriver internal driver;
    uint32 internal totalSplitsWeight;
    address internal admin = address(1);

    function setUp() public {
        BeamsHub hubLogic = new BeamsHub(10);
        beamsHub = BeamsHub(address(new ManagedProxy(hubLogic, address(this))));

        // Make the driver ID non-0 to test if it's respected by the driver
        beamsHub.registerDriver(address(1));
        beamsHub.registerDriver(address(2));
        beamsHub.registerDriver(address(3));
        uint32 driverId = beamsHub.registerDriver(address(this));
        ImmutableSplitsDriver driverLogic = new ImmutableSplitsDriver(
            beamsHub,
            driverId
        );
        driver = ImmutableSplitsDriver(
            address(new ManagedProxy(driverLogic, admin))
        );
        beamsHub.updateDriverAddress(driverId, address(driver));
        totalSplitsWeight = driver.totalSplitsWeight();
    }

    function testCreateSplits() public {
        SplitsReceiver[] memory receivers = new SplitsReceiver[](2);
        receivers[0] = SplitsReceiver({
            userId: 1,
            weight: totalSplitsWeight - 1
        });
        receivers[1] = SplitsReceiver({userId: 2, weight: 1});
        uint256 nextUserId = driver.nextUserId();
        UserMetadata[] memory metadata = new UserMetadata[](1);
        metadata[0] = UserMetadata("key", "value");

        uint256 userId = driver.createSplits(receivers, metadata);

        assertEq(userId, nextUserId, "Invalid user ID");
        assertEq(driver.nextUserId(), userId + 1, "Invalid next user ID");
        bytes32 actual = beamsHub.splitsHash(userId);
        bytes32 expected = beamsHub.hashSplits(receivers);
        assertEq(actual, expected, "Invalid splits hash");
    }

    function testCreateSplitsRevertsWhenWeightsSumTooLow() public {
        SplitsReceiver[] memory receivers = new SplitsReceiver[](2);
        receivers[0] = SplitsReceiver({
            userId: 1,
            weight: totalSplitsWeight - 2
        });
        receivers[1] = SplitsReceiver({userId: 2, weight: 1});

        vm.expectRevert("Invalid total receivers weight");
        driver.createSplits(receivers, new UserMetadata[](0));
    }

    function testSetSplitsCanBePaused() public {
        vm.prank(admin);
        driver.pause();
        vm.expectRevert("Contract paused");
        driver.createSplits(new SplitsReceiver[](0), new UserMetadata[](0));
    }
}
