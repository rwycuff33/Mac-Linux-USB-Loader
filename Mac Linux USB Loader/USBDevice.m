//
//  USBDevice.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 11/26/12.
//  Copyright (c) 2012 SevenBits. All rights reserved.
//

#import "USBDevice.h"

@implementation USBDevice

- (BOOL)prepareUSB:(NSString *)path {
    // Get an NSFileManager.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Construct our strings that we need.
    NSString *bootLoaderName = [[NSUserDefaults standardUserDefaults] stringForKey:@"selectedFirmwareType"];
    NSString *bootLoaderPath, *grubLoaderPath;
    NSLog(@"Selected firmware type: %@", bootLoaderName);
    
    if ([bootLoaderName isEqualToString:@"Legacy Loader"]) {
        bootLoaderPath = [[NSBundle mainBundle] pathForResource:@"bootX64-legacy" ofType:@"efi" inDirectory:@""];
        grubLoaderPath = @"";
    } else if ([bootLoaderName isEqualToString:@"Enterprise EFI Linux Loader"]) {
        bootLoaderPath = [[NSBundle mainBundle] pathForResource:@"bootX64" ofType:@"efi" inDirectory:@""];
        grubLoaderPath = [[NSBundle mainBundle] pathForResource:@"boot" ofType:@"efi" inDirectory:@""];
    } else {
        NSString *errorMessage = [NSString stringWithFormat:@"Unsupported firmware type: %@", bootLoaderName];
        NSLog(@"Error: %@", errorMessage);
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"ABORT", nil)];
        [alert setInformativeText:NSLocalizedString(@"FAILED-CREATE-BOOTABLE-USB", nil)];
        [alert setInformativeText:errorMessage];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
    
    NSString *finalPath = [path stringByAppendingPathComponent:@"/efi/boot/bootX64.efi"];
    NSString *finalLoaderPath = [path stringByAppendingPathComponent:@"/efi/boot/boot.efi"];
    NSString *tempPath = [path stringByAppendingPathComponent:@"/efi/boot"];
    
    // Check if either if the required booting images is present..
    BOOL fileExists = [fileManager fileExistsAtPath:finalPath] & [fileManager fileExistsAtPath:finalLoaderPath];
    
    // Should be relatively self-explanatory. If there's already EFI executables, show an error message.
    if (fileExists == YES) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"ABORT", nil)];
        [alert setMessageText:NSLocalizedString(@"FAILED-CREATE-BOOTABLE-USB", nil)];
        [alert setInformativeText:@"There is already EFI firmware on this device. If it is from a previous run of Mac Linux USB Loader, you must delete the EFI folder on the USB drive and then run this tool."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
        
        [[NSApp delegate] setCanQuit:YES];
    }
    
    // Make the folder to hold the EFI executable and ISO to boot.
    [fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Copy the EFI bootloader. Do different things depending on which firmware is to be installed.
    BOOL returnValue = NO;
    if ([bootLoaderName isEqualToString:@"Enterprise EFI Linux Loader"]) {
        BOOL enterpriseInstallSuccess = NO, grubInstallSuccess = NO;
        if ([fileManager copyItemAtPath:bootLoaderPath toPath:finalPath error:nil] == NO) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"ABORT", nil)];
            [alert setMessageText:NSLocalizedString(@"FAILED-CREATE-BOOTABLE-USB", nil)];
            [alert setInformativeText:@"Could not copy Enterprise to the USB device."];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        } else {
            enterpriseInstallSuccess = YES;
        }
    
        if ([fileManager copyItemAtPath:grubLoaderPath toPath:finalLoaderPath error:nil] == NO) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"ABORT", nil)];
            [alert setMessageText:NSLocalizedString(@"FAILED-CREATE-BOOTABLE-USB", nil)];
            [alert setInformativeText:@"Could not copy the EFI bootloader to the USB device."];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        } else {
            grubInstallSuccess = YES;
        }
        
        // Only return true if both operations are successful.
        returnValue = enterpriseInstallSuccess & grubInstallSuccess;
    } else {
        if ([fileManager copyItemAtPath:bootLoaderPath toPath:finalPath error:nil] == NO) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"ABORT", nil)];
            [alert setMessageText:NSLocalizedString(@"FAILED-CREATE-BOOTABLE-USB", nil)];
            [alert setInformativeText:@"Could not copy the EFI bootloader to the USB device."];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
            returnValue = NO;
        } else {
            returnValue = YES;
        }
    }
    
    return returnValue;
}

- (void)markUsbAsLive:(NSString*)path distributionFamily:(NSString *)family {
    NSLog(@"Marking this USB as a live USB...");
    
    NSString *filePath = [path stringByAppendingPathComponent:@"/efi/boot/.MLUL-Live-USB"];
    NSString *stringToWrite = @"";
    stringToWrite = [stringToWrite
                     stringByAppendingString:@"# This file is machine generated and required by Mac Linux USB Loader and Enterprise.\n"];
    stringToWrite = [stringToWrite stringByAppendingString:@"# Do not modify it unless you know what you're doing.\n"];
    stringToWrite = [stringToWrite stringByAppendingString:
                     [NSString stringWithFormat:@"family %@\n", family]]; // Hard code for now.
    
    [stringToWrite writeToFile:filePath atomically:NO encoding:NSASCIIStringEncoding error:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // Empty because under normal processing we need not do anything here.
}

@end
