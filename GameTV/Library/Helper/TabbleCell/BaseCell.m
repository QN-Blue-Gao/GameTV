//
//  BaseCell.m
//  NhacDj
//
//  Created by Hai Trieu on 9/29/14.
//  Copyright (c) 2014 Hai Trieu. All rights reserved.
//

#import "BaseCell.h"

@interface BaseCell ()


@end

@implementation BaseCell

- (void)awakeFromNib {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setThumbnailUrl:(NSString *)thumbnailUrl{
    _thumbnailUrl = thumbnailUrl;
    [_imgThumbnail setImageWithURL:[NSURL URLWithString:[thumbnailUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"no_image"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image && cacheType == SDImageCacheTypeNone)
        {
            _imgThumbnail.alpha = 0.0;
            [UIView animateWithDuration:1.0
                             animations:^{
                                 _imgThumbnail.alpha = 1.0;
                             }];
        }
    } usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

-(void)setTitle:(NSString *)title{
    _title = title;
    _lblTitle.text = title;
}

@end
