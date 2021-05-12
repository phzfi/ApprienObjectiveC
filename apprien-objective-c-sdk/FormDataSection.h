//
//  FormDataSection.h
//  apprien-objective-c-sdk
//
//  Created by phz on 12.5.2021.
//

#ifndef FormDataSection_h
#define FormDataSection_h
@interface FormDataSection : NSObject

/*!
 @abstract The section's name.
*/
@property(nonatomic) NSString *Name;

/*!
 @abstract Binary data contained in this section.
*/
@property(nonatomic) char *Data;

@end
#endif /* FormDataSection_h */
