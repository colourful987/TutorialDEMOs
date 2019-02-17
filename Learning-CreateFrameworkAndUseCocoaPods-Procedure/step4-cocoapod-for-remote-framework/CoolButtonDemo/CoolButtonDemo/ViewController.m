//
//  ViewController.m
//  CoolButtonDemo
//
//  Created by pmst on 2019/2/17.
//  Copyright © 2019 pmst. All rights reserved.
//

#import "ViewController.h"
#import <NDCoolControl/NDCoolControl.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet NDCoolButton *coolButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)hueValueChanged:(id)sender {
    self.coolButton.hue = ((UISlider *)sender).value;
}

- (IBAction)saturationValueChanged:(id)sender {
    self.coolButton.saturation = ((UISlider *)sender).value;
}

- (IBAction)brightnessValueChanged:(id)sender {
    self.coolButton.brightness = ((UISlider *)sender).value;
}

@end
