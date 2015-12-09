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
@property(nonatomic,strong) IBInspectable   UIColor     *progressDownloadColor;
@property(nonatomic,strong) IBInspectable   UIColor     *progressUploadColor;
/*!
 Equivalent to isDownloading = -1, no loading = 0, isUploading = 1
 Could have used enum but doesn't help with inspectable property.
 */
@property(nonatomic,assign) IBInspectable   NSInteger   direction;
/*!
 Progress percent -100 (downloading) to 100 (uploading)
 */
@property(nonatomic,assign)IBInspectable CGFloat        progress;

-(void) setDirection:(NSInteger)direction progress: (CGFloat)progress;

@end
