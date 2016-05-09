//
//  PageVC.swift
//  NavPageVCDemo
//
//  Created by langyue on 16/5/9.
//  Copyright © 2016年 langyue. All rights reserved.
//

import Foundation

import UIKit
import SnapKit




//segment的高度
let PageVCSegmanetHeight : CGFloat = 40.0
//标签背景的高度 PS:两个样式
let PageVCSegmentIndicatorHeight = 32.0
let PageVCSegmentIndicatorHeightLine = 3.0

//可见的最大Pages
let PageVCMaxVisiblePages = 6





enum PageVCEditMode : Int{
    case Default = 0
    case Editing
    
    
    func typeName() -> String {
        return "UIViewAnimationCurve"
    }
    
    
    func toBool()->Bool{
        
        if self == .Default {
            return true
        }
        
        if self == .Editing {
            return false
        }
        
    }
    
    
}


extension PageVCEditMode{
    
    func description() -> String {
        
        switch self {
        case .Default:
            return "ModeDefault"
        case .Editing:
            return "ModeEditing"
        }
        
    }
    
}





enum PageVCSegmentStyle : Int {
    case Default
    case LineHighlight
    func typeName() -> String {
        return "PageVCSegmentStyle"
    }
}



extension PageVCSegmentStyle{
    
    func description() -> String {
        switch self {
        case .Default:
            return "Default"
        case .LineHighlight:
            return "LineHighlight"
        }
    }
    
}







protocol PageVCDataSource {
    //设置点击pageVCIndex的vc
    func pageVC(pageVC:PageVC, viewControllerAtIndex index:NSInteger)->UIViewController
    //设置点击pageVCIndex的title
    func pageVC(pageVC:PageVC,titleAtIndex index:NSInteger)->String
    //设置栏目的个数
    func numberOfContentForPageVC(pageVC:PageVC)->NSInteger
}


protocol PageVCDelegate {
    
    //不一定需要实现以下方法
    
    //将要改变到index
    func pageVC(pageVC:PageVC,willChangeToIndex toIndex:NSInteger,fromIndex:NSInteger)
    //已经改变到index
    func pageVC(pageVC:PageVC,didChangeToIndex toIndex:NSInteger,fromIndex:NSInteger)
    //在index处已点击 此方法暂时不适用
    func pageVC(pageVC:PageVC,didClickAtIndex index:NSInteger)
    //点击Edit按钮的mode
    func pageVC(pageVC:PageVC,didClickEditMode mode:PageVCEditMode)
}






class PageVC: BaseVC,UIScrollViewDelegate {
    
    
    
    var _segmentContrainerView : UIView //Container 容器 - 上面的SegmentCV
    var _contentContainerView : UIView   //Contriner 容器 - 下面的滚动视图
    var _indicatorView : UIView //indicator 指示器 - 标签下面的杠杠
    
    var _doneLayout:Bool
    var _editMode: Bool
    
    
    
    var numberOfContent : NSInteger = 0
    var currentIndex : NSInteger
    var lastIndex : UIView
    
    var segmentTitles : NSMutableArray
    var reusableVCDic : NSMutableDictionary
    var size : CGSize
    
    
    
    
    
    
    
    
    
    
    
    
    var contentScrollView : UIScrollView!
    var segmentScrollView : UIScrollView!
    
    
    
    
    var dataSource : PageVCDataSource!
    var delegate : PageVCDelegate!
    var segmentStyle :PageVCSegmentStyle!
    var nornalTextColor : UIColor!
    var highightTextColor : UIColor!
    var lineBackground : UIColor!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.defaultSetup()
        
        
        
    }
    
    //MARK: 默认设置
    func defaultSetup(){
        
        
        self.automaticallyAdjustsScrollViewInsets = false
        _editMode =   PageVCEditMode.Default.toBool()
        
        currentIndex = 0
        
        //是创建UI 首先是创建segment 的滚动视图
        
        segmentScrollView = UIScrollView()
        //是否显示水平和垂直滚动条
        segmentScrollView.showsHorizontalScrollIndicator = false
        segmentScrollView.showsVerticalScrollIndicator = false
        
        segmentScrollView.scrollsToTop = false //To Top
        segmentScrollView.bounces = false
        
        
        segmentScrollView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        self.view.addSubview(segmentScrollView)
        
        
        
        segmentScrollView.snp_makeConstraints { (make) in
            
            
            make.left.equalTo(self.view)
            make.top.equalTo(self.snp_topLayoutGuideTop)
            
            make.height.equalTo(PageVCSegmentIndicatorHeight)
            
        }
        
        
        //创建editButton
        let editBgView = UIControl()
        editBgView.addTarget(self, action: Selector("editButtonAction"), forControlEvents: .TouchUpInside)
        self.view.addSubview(editBgView)
        
        editBgView.snp_makeConstraints { (make) in
        
            make.top.bottom.equalTo(segmentScrollView)
            make.left.equalTo(segmentScrollView.snp_right)
            make.right.equalTo(self.view)
            make.width.equalTo(segmentScrollView.snp_height)
            
        }
        
        
        
        //edit按钮左边的横线
        let lineView = UIView()
        lineView.backgroundColor = UIColor.lightGrayColor()
        editBgView.addSubview(lineView)
        
        lineView.snp_makeConstraints { (make) in
            make.left.top.bottom.equalTo(editBgView)
            make.width.equalTo(1)
        }
        
        
        //创建edit按钮
        let editButton = UIButton(type: .Custom)
        editButton.setBackgroundImage(UIImage(named: "home_edit_column"), forState: .Normal)
        editButton.addTarget(self, action: Selector("editButtonAction"), forControlEvents: .TouchUpInside)
        editBgView.addSubview(editButton)
        editButton.snp_makeConstraints { (make) in
            make.center.equalTo(editBgView)
        }
        
        
        //PS 翻转一个add顺序
        //杠杠内容容器视图
        _indicatorView = UIView()
        segmentScrollView.addSubview(_indicatorView)
        
        
        //segment 内容容器视图
        _segmentContrainerView = UIView()
        segmentScrollView.addSubview(_segmentContrainerView)
        segmentScrollView.snp_makeConstraints { (make) in
            //edges其实就是top left bottom right的一个简化
            make.edges.equalTo(segmentScrollView)
            make.height.equalTo(segmentScrollView.snp_height)
            
        }
        
        
        //内容视图
        contentScrollView = UIScrollView()
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.scrollsToTop = false
        contentScrollView.delegate = self
        contentScrollView.pagingEnabled = true
        contentScrollView.bounces = false
        self.view.addSubview(contentScrollView)
        
        
        
        contentScrollView.snp_makeConstraints { (make) in
            
            make.left.right.equalTo(self.view)
            make.top.equalTo(segmentScrollView.snp_bottom)
            make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
            
        }
        
        //内容容器视图
        _contentContainerView = UIView()
        contentScrollView.addSubview(_contentContainerView)
        _contentContainerView.snp_makeConstraints { (make) in
            make.edges.equalTo(contentScrollView)
            make.height.equalTo(contentScrollView)
        }
        
        //Code ..
        segmentTitles = NSMutableArray()
        reusableVCDic = NSMutableDictionary()
        _doneLayout = false
        
    }
    
    
    
    
    
    
    //刷新数据
    func reloadData() -> Void {
        
        
        
    }
    
    
    //刷新一个具体的栏目
    func reloadDataAtIndex(index:NSInteger) -> Void {
        
        
        
    }
    
    //根据index获取对应的vc
    func viewControllerAtIndex(index:NSInteger) -> UIViewController {
        
        
        
        
        
    }
    
    
    
    
    
}




class BaseVC: UIViewController {
    
    
    var contentLineImgView : UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentLineImgView = self.findHairlineImageViewUnder((self.navigationController?.navigationBar)!)
    }
    
    //隐藏导航栏下面的那直线
    func findHairlineImageViewUnder(view:UIView)->UIImageView?{
        if (view is UIImageView) && view.bounds.size.height <= 1.0 {
            return view as? UIImageView
        }
        for item in view.subviews {
            let imgView  = self.findHairlineImageViewUnder(item)
            if imgView != nil {
                return imgView
            }
        }
        return nil
    }
    
}