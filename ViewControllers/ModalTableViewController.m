//
//  modalTableViewViewController.m
//  ThisWifiSucks
//
//  Created by Ryan Berg on 12/25/13.
//  Copyright (c) 2013 Ryan Berg. All rights reserved.
//

#import "ModalTableViewViewController.h"

@interface ModalTableViewViewController ()

@end

@implementation ModalTableViewViewController
{
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Location %d", indexPath.row];
    
    return cell;
}

- (IBAction)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES]; ;
}

- (IBAction)poweredByFS:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://foursquare.com/"]];
}
@end
