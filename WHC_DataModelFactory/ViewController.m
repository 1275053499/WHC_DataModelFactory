//
//  ViewController.m
//  WHC_DataModelFactory
//
//  Created by 吴海超 on 15/4/30.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//


// Github <https://github.com/netyouli/WHC_DataModelFactory>

//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ViewController.h"
#import "WHC_XMLParser.h"
#import <objc/runtime.h>

#define kWHC_DEFAULT_CLASS_NAME @("WHC")
#define kWHC_CLASS       @("\n@interface %@ :NSObject\n%@\n@end\n")
#define kWHC_PROPERTY(s)    ((s) == 'c' ? @("@property (nonatomic , copy) %@              * %@;\n") : @("@property (nonatomic , strong) %@              * %@;\n"))
#define kWHC_ASSIGN_PROPERTY    @("@property (nonatomic , assign) %@              %@;\n")
#define kWHC_CLASS_M     @("@implementation %@\n\n@end\n")

#define kWHC_CLASS_Prefix_M     @("@implementation %@\n+ (NSString *)prefix;\n@end\n\n")

#define kWHC_Prefix_M_Func @("+ (NSString *)prefix {\n    return @\"%@\";\n}\n")

#define kSWHC_Prefix_Func @("class func prefix() -> String {\n    return \"%@\"\n}\n")

#define kSWHC_CLASS @("\n@objc(%@)\nclass %@ :NSObject{\n%@\n}")
#define kSWHC_PROPERTY @("var %@: %@!\n")
@interface ViewController (){
    NSMutableString       *   _classString;        //存类头文件内容
    NSMutableString       *   _classMString;       //存类源文件内容
    NSString              *   _classPrefixName;    //类前缀
}

@property (nonatomic , strong)IBOutlet  NSTextField  * classNameField;
@property (nonatomic , strong)IBOutlet  NSTextField  * jsonField;
@property (nonatomic , strong)IBOutlet  NSTextField  * classField;
@property (nonatomic , strong)IBOutlet  NSTextField  * classMField;
@property (nonatomic , strong)IBOutlet  NSTextField  * classPrefixField;
@property (nonatomic , strong)IBOutlet  NSButton       * checkBox;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _classString = [NSMutableString new];
    _classMString = [NSMutableString new];
    _classField.editable = NO;
    _classMField.editable = NO;
    _jsonField.drawsBackground = NO;
    _classField.drawsBackground = NO;
    _classMField.drawsBackground = NO;
    // Do any additional setup after loading the view.
}

- (IBAction)clickRadioButtone:(NSButton *)sender{
}

- (IBAction)clickMakeButton:(NSButton*)sender{
    [_classString deleteCharactersInRange:NSMakeRange(0, _classString.length)];
    [_classMString deleteCharactersInRange:NSMakeRange(0, _classMString.length)];
    NSString  * className = _classNameField.stringValue;
    NSString  * json = _jsonField.stringValue;
    _classPrefixName = _classPrefixField.stringValue == nil ? @"" : _classPrefixField.stringValue;
    if(className == nil){
        className = kWHC_DEFAULT_CLASS_NAME;
    }
    if(className.length == 0){
        className = kWHC_DEFAULT_CLASS_NAME;
    }
    if(json && json.length){
        NSDictionary  * dict = nil;
        if([json hasPrefix:@"<"]){
            //xml
            dict = [WHC_XMLParser dictionaryForXMLString:json];
        }else{
            //json
            NSData  * jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
            dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:NULL];
        }
        if(_checkBox.state == 0){
            if (_classPrefixName.length > 0) {
                [_classMString appendFormat:kWHC_CLASS_Prefix_M,className];
            }else {
                [_classMString appendFormat:kWHC_CLASS_M,className];
            }
            [_classString appendFormat:kWHC_CLASS,className,[self handleDataEngine:dict key:@""]];
        }else{
            [_classString appendFormat:kSWHC_CLASS,className,className,[self handleDataEngine:dict key:@""]];
        }
        _classField.stringValue = _classString;
        _classMField.stringValue = _classMString;
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        NSAlert * alert = [NSAlert alertWithMessageText:@"WHC" defaultButton:@"确定" alternateButton:nil otherButton:nil informativeTextWithFormat:@"json或者xml数据不能为空"];
        [alert runModal];
#pragma clang diagnostic pop
    }
}

- (NSString *)handleAfterClassName:(NSString *)className {
    NSString * first = [className substringToIndex:1];
    NSString * other = [className substringFromIndex:1];
    return [NSString stringWithFormat:@"%@%@%@",_classPrefixName,[first uppercaseString],other];
}

#pragma mark -解析处理引擎-

- (NSString*)handleDataEngine:(id)object key:(NSString*)key{
    if(object){
        NSMutableString  * property = [NSMutableString new];
        if([object isKindOfClass:[NSDictionary class]]){
            NSDictionary  * dict = object;
            NSInteger       count = dict.count;
            NSArray       * keyArr = [dict allKeys];
            if (_classPrefixName.length > 0) {
                if (_checkBox.state == 0) {
                    [property appendFormat:kWHC_Prefix_M_Func,_classPrefixName];
                }else {
                    [property appendFormat:kSWHC_Prefix_Func,_classPrefixName];
                }
            }
            for (NSInteger i = 0; i < count; i++) {
                id subObject = dict[keyArr[i]];
                NSString * className = [self handleAfterClassName:keyArr[i]];
                if([subObject isKindOfClass:[NSDictionary class]]){
                    NSString * classContent = [self handleDataEngine:subObject key:keyArr[i]];
                    if(_checkBox.state == 0){
                        [property appendFormat:kWHC_PROPERTY('s'),className,keyArr[i]];
                        [_classString appendFormat:kWHC_CLASS,className,classContent];
                        if (_classPrefixName.length > 0) {
                            [_classMString appendFormat:kWHC_CLASS_Prefix_M,className];
                        }else {
                            [_classMString appendFormat:kWHC_CLASS_M,className];
                        }
                    }else{
                        [property appendFormat:kSWHC_PROPERTY,keyArr[i],className];
                        [_classString appendFormat:kSWHC_CLASS,className,className,classContent];
                    }
                }else if ([subObject isKindOfClass:[NSArray class]]){
                    NSString * classContent = [self handleDataEngine:subObject key:keyArr[i]];
                    if(_checkBox.state == 0){
                        [property appendFormat:kWHC_PROPERTY('s'),[NSString stringWithFormat:@"NSArray<%@ *>",className],keyArr[i]];
                        [_classString appendFormat:kWHC_CLASS,className,classContent];
                        if (_classPrefixName.length > 0) {
                            [_classMString appendFormat:kWHC_CLASS_Prefix_M,className];
                        }else {
                            [_classMString appendFormat:kWHC_CLASS_M,className];
                        }
                    }else{
                        [property appendFormat:kSWHC_PROPERTY,keyArr[i],[NSString stringWithFormat:@"[%@]",className]];
                        [_classString appendFormat:kSWHC_CLASS,className,className,classContent];
                    }
                }else if ([subObject isKindOfClass:[NSString class]]){
                    if(_checkBox.state == 0){
                        [property appendFormat:kWHC_PROPERTY('c'),@"NSString",keyArr[i]];
                    }else{
                        [property appendFormat:kSWHC_PROPERTY,keyArr[i],@"String"];
                    }
                }else if ([subObject isKindOfClass:[NSNumber class]]){
                    if(_checkBox.state == 0){
                        if (strcmp([subObject objCType], @encode(float)) == 0 ||
                            strcmp([subObject objCType], @encode(CGFloat)) == 0) {
                            [property appendFormat:kWHC_ASSIGN_PROPERTY,@"CGFloat",keyArr[i]];
                        }else if (strcmp([subObject objCType], @encode(double)) == 0) {
                            [property appendFormat:kWHC_ASSIGN_PROPERTY,@"double",keyArr[i]];
                        }else if (strcmp([subObject objCType], @encode(BOOL)) == 0) {
                            [property appendFormat:kWHC_ASSIGN_PROPERTY,@"Bool",keyArr[i]];
                        }else {
                            [property appendFormat:kWHC_ASSIGN_PROPERTY,@"NSInteger",keyArr[i]];
                        }
                    }else{
                        if (strcmp([subObject objCType], @encode(float)) == 0 ||
                            strcmp([subObject objCType], @encode(CGFloat)) == 0) {
                            [property appendFormat:kSWHC_PROPERTY,keyArr[i],@"CGFloat"];
                        }else if (strcmp([subObject objCType], @encode(double)) == 0) {
                            [property appendFormat:kSWHC_PROPERTY,keyArr[i],@"Double"];
                        }else if (strcmp([subObject objCType], @encode(BOOL)) == 0) {
                            [property appendFormat:kSWHC_PROPERTY,keyArr[i],@"Bool"];
                        }else {
                            [property appendFormat:kSWHC_PROPERTY,keyArr[i],@"Int"];
                        }
                    }
                }else{
                    if(subObject == nil){
                        if(_checkBox.state == 0){
                            [property appendFormat:kWHC_PROPERTY('c'),@"NSString",keyArr[i]];
                        }else{
                            [property appendFormat:kSWHC_PROPERTY,keyArr[i],@"String"];
                        }
                    }else if([subObject isKindOfClass:[NSNull class]]){
                        if(_checkBox.state == 0){
                            [property appendFormat:kWHC_PROPERTY('c'),@"NSString",keyArr[i]];
                        }else{
                            [property appendFormat:kSWHC_PROPERTY,keyArr[i],@"String"];
                        }
                    }
                }
            }
        }else if ([object isKindOfClass:[NSArray class]]){
            NSArray  * dictArr = object;
            NSUInteger  count = dictArr.count;
            if(count){
                NSObject  * tempObject = dictArr[0];
                for (NSInteger i = 0; i < dictArr.count; i++) {
                    NSObject * subObject = dictArr[i];
                    if([subObject isKindOfClass:[NSDictionary class]]){
                        if(((NSDictionary *)subObject).count > ((NSDictionary *)tempObject).count){
                            tempObject = subObject;
                        }
                    }
                    if([subObject isKindOfClass:[NSDictionary class]]){
                        if(((NSArray *)subObject).count > ((NSArray *)tempObject).count){
                            tempObject = subObject;
                        }
                    }
                }
                [property appendString:[self handleDataEngine:tempObject key:key]];
            }
        }else{
            NSLog(@"key = %@",key);
        }
        return property;
    }
    return @"";
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
