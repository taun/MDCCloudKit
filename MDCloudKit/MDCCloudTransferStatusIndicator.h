//
//  Created by Taun Chapman on 12/08/15.
//  Copyright © 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

IB_DESIGNABLE

/*!
 A view for showing the status of cloud uploads and downloads.
 
 Zero means zero progress.
 +1 means full upload complete.
 -1 means full download complete.
 */
@interface MDCCloudTransferStatusIndicator : UIView

@property(nonatomic,strong) IBInspectable   UIColor     *outlineColor;
@property(nonatomic,strong) IBInspectable   UIColor     *fillColor;
@property(nonatomic,strong) IBInspectable   UIColor     *progressColor;
@property(nonatomic,assign)IBInspectable CGFloat        progress;

@end
