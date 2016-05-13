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
let PageVCSegmenttHeight : CGFloat = 40.0
//标签背景的高度 PS:两个样式
let PageVCSegmentIndicatorHeight : CGFloat = 32.0
let PageVCSegmentIndicatorHeightLine : CGFloat = 3.0

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
        }else{
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
    func pageVC(pageVC:PageVC?, viewControllerAtIndex index:NSInteger?)->UIViewController
    //设置点击pageVCIndex的title
    func pageVC(pageVC:PageVC?,titleAtIndex index:NSInteger?)->String
    //设置栏目的个数
    func numberOfContentForPageVC(pageVC:PageVC?)->NSInteger?
}


protocol PageVCDelegate {
    //不一定需要实现以下方法
    //将要改变到index
    func pageVC(pageVC:PageVC?,willChangeToIndex toIndex:NSInteger?,fromIndex:NSInteger?)
    //已经改变到index
    func pageVC(pageVC:PageVC?,didChangeToIndex toIndex:NSInteger?,fromIndex:NSInteger?)
    //在index处已点击 此方法暂时不适用
    func pageVC(pageVC:PageVC?,didClickAtIndex index:NSInteger?)
    //点击Edit按钮的mode
    func pageVC(pageVC:PageVC?,didClickEditMode mode:PageVCEditMode)
}



class PageVC: BaseVC,UIScrollViewDelegate {
    
    var _segmentContainerView : UIView? //Container 容器 - 上面的SegmentCV
    var _contentContainerView : UIView!   //Contriner 容器 - 下面的滚动视图
    var indicatorView : UIView? //indicator 指示器 - 标签下面的杠杠
    
    var _doneLayout:Bool!
    var _editMode: Bool!
    
    
    var numberOfContent : NSInteger?
    var lastIndex : NSInteger!
    
    var segmentTitles : NSMutableArray = []
    var reusableVCDic : NSMutableDictionary = [:]
    var size : CGSize!
    
    
    var contentScrollView : UIScrollView!
    var segmentScrollView : UIScrollView!
    
    
    var segmentStyle :PageVCSegmentStyle!
    var normalTextColor : UIColor!
    var highightTextColor : UIColor!
    var lineBackground : UIColor!
    
    
    var delegate : PageVCDelegate?
    
    func makeChangeAction(){
        
    }
    
    
    private var _currentIndex : NSInteger = 0
    var currentIndex : NSInteger {
        
        set{
            
            delegate?.pageVC(self, willChangeToIndex: newValue, fromIndex: currentIndex)
            let oldLabel = _segmentContainerView?.viewWithTag(1000 + currentIndex) as? UILabel
            let newLabel = _segmentContainerView?.viewWithTag(1000 + newValue) as? UILabel
            oldLabel?.highlighted = false
            newLabel?.highlighted = true
            
            lastIndex = currentIndex
            _currentIndex = newValue
            
            
            UIView.animateWithDuration(0.3) {
                
                let currentLabel = self._segmentContainerView?.viewWithTag(1000 + self._currentIndex)
                
                var frame = currentLabel?.frame
                if frame == nil {
                    frame = CGRectZero
                }
                
                if self.segmentStyle == PageVCSegmentStyle.Default {
                    self.indicatorView?.frame = CGRectMake(CGRectGetMinX(frame!)+6, CGRectGetHeight(frame!)-PageVCSegmentIndicatorHeight, CGRectGetWidth(frame!)-12, PageVCSegmentIndicatorHeight - 8)
                }
                
                if self.segmentStyle == PageVCSegmentStyle.LineHighlight {
                    self.indicatorView?.frame = CGRectMake(CGRectGetMinX(frame!), CGRectGetHeight(frame!) - PageVCSegmentIndicatorHeightLine, CGRectGetWidth(frame!), PageVCSegmentIndicatorHeightLine)
                }
                
            }
            self.updateSegmentContentOffset()
            delegate?.pageVC(self, didChangeToIndex: currentIndex, fromIndex: lastIndex)
        }
        
        get{
            return _currentIndex
        }
        
    }
    
    
    
    
    private var _dataSource : PageVCDataSource?
    var dataSource : PageVCDataSource?{
        didSet{
            if dataSource != nil {
                self.reloadData()
            }
        }
    }
    
    
    func updateSegmentContentOffset(){
        
        let currentLabel = _segmentContainerView?.viewWithTag(1000 + currentIndex)
        var rect : CGRect? = currentLabel?.frame
        if rect == nil {
            rect = CGRectZero
        }
        
        let midX = CGRectGetMidX(rect!)
        
        var offset : CGFloat = 0
        var contentWidth = segmentScrollView?.contentSize.width
        if contentWidth == nil {
            contentWidth = 0
        }
        
        let halfWidth = CGRectGetWidth( (segmentScrollView?.bounds == nil ? CGRectZero : (segmentScrollView?.bounds)!) ) / 2
        
        if midX < halfWidth {
            offset = 0
        }else if(midX > contentWidth! - halfWidth){
            offset = contentWidth! - 2 * halfWidth
        }else{
            offset = midX - halfWidth
        }
        
        segmentScrollView?.setContentOffset(CGPointMake(offset, 0), animated: true )
    }
    
    
    
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
            make.top.equalTo(self.snp_topLayoutGuideBottom)
            
            make.height.equalTo(PageVCSegmentIndicatorHeight)
        }
        
        
        //创建editButton
        let editBgView = UIControl()
        editBgView.addTarget(self, action: #selector(PageVC.editButtonAction), forControlEvents: .TouchUpInside)
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
        editButton.addTarget(self, action: #selector(PageVC.editButtonAction), forControlEvents: .TouchUpInside)
        editBgView.addSubview(editButton)
        editButton.snp_makeConstraints { (make) in
            make.center.equalTo(editBgView)
        }
        
        
        //PS 翻转一个add顺序
        //杠杠内容容器视图
        indicatorView = UIView()
        segmentScrollView.addSubview(indicatorView!)
        
        
        //segment 内容容器视图
        _segmentContainerView = UIView()
        segmentScrollView.addSubview(_segmentContainerView!)
        _segmentContainerView!.snp_makeConstraints { (make) in
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
        
        _doneLayout = false
        reusableVCDic.removeAllObjects()
        numberOfContent = dataSource?.numberOfContentForPageVC(self)
        if numberOfContent == 0 {
            return
        }
        
        segmentTitles.removeAllObjects()
        
        let arr = NSArray(array: _segmentContainerView!.subviews)
        let arr1 = NSArray(array: _contentContainerView.subviews)
        
        for (_,value) in arr.enumerate() {
            let view = value as! UIView
            view.removeFromSuperview()
        }
        
        
        for (_,value) in  arr1.enumerate(){
            let view = value as! UIView
            view.removeFromSuperview()
        }
        
        
        var lastSegmentView : UIView? = nil
        var lastContentView : UIView? = nil
        
        delegate?.pageVC(self, willChangeToIndex: 0, fromIndex: -1)
        
        currentIndex = 0
        
        
        if numberOfContent == nil {
            numberOfContent = 1
        }
        
        
        
        for idx in 0...numberOfContent!-1 {
            
            //load segment
            var title = dataSource?.pageVC(self, titleAtIndex: idx)
            if title == nil {
                title = ""
            }
            segmentTitles.addObject(title!)
            
            
            let label = UILabel()
            label.userInteractionEnabled = true
            label.text = title
            label.textColor = self.normalTextColor
            label.font = UIFont.systemFontOfSize(16.0)
            label.textAlignment = NSTextAlignment.Center
            label.highlightedTextColor = highightTextColor
            label.tag = 1000 + idx
            
            //改进适配字数
            
            let sizeStr : NSString = NSString(string:label.text!)
            let size = sizeStr.sizeWithAttributes([NSFontAttributeName:UIFont.systemFontOfSize(16.0)])
            self.size = size
            
            let tapGesture = UITapGestureRecognizer(target: self , action: #selector(PageVC.tapSegmentItemAction(_:)))
            label.addGestureRecognizer(tapGesture)
            
            if indicatorView == nil {
                indicatorView = UIView()
            }
            _segmentContainerView!.insertSubview(label, aboveSubview: indicatorView!)
            
            label.snp_makeConstraints(closure: { (make) in
                make.top.bottom.equalTo(_segmentContainerView!)
                if lastSegmentView != nil {
                    make.left.equalTo(lastSegmentView!.snp_right)
                }else{
                    make.left.equalTo(_segmentContainerView!.snp_left)
                }
                var sizeTest = self.size
                sizeTest.width = sizeTest.width + 24
                make.width.equalTo(sizeTest)
            })
            
            
            
            lastSegmentView = label
            let view = UIView()
            view.tag = 2000 + idx
            _contentContainerView.addSubview(view)
            
            view.snp_makeConstraints(closure: { (make) in
                make.top.bottom.equalTo(_contentContainerView)
                if lastContentView != nil {
                    make.left.equalTo(lastContentView!.snp_right)
                }else{
                    make.left.equalTo(_contentContainerView.snp_left)
                }
                make.width.equalTo(CGRectGetWidth(UIScreen.mainScreen().bounds))
            })
            
            lastContentView = view
            
            
            let controller = dataSource?.pageVC(self, viewControllerAtIndex: idx)
            
            if controller != nil {
                self.addChildViewController(controller!)
                reusableVCDic.setObject(controller!, forKey: idx)
                view.addSubview(controller!.view)
                
                controller!.view.snp_makeConstraints(closure: { (make) in
                    make.edges.equalTo(view)
                })
            }
            
        }
        
        
        _segmentContainerView!.snp_makeConstraints { (make) in
            make.right.equalTo(lastSegmentView!.snp_right)
        }
        _contentContainerView.snp_makeConstraints { (make) in
            make.right.equalTo(lastContentView!.snp_right)
            
        }
        
        
        let currentLabel = _segmentContainerView!.viewWithTag(1000 + currentIndex) as! UILabel
        currentLabel.highlighted = true
        self.view.layoutIfNeeded()
        
        
        let frame = currentLabel.frame
        
        if segmentStyle == PageVCSegmentStyle.Default {
            indicatorView?.frame = CGRectMake(CGRectGetMinX(frame)+CGFloat(6), CGRectGetHeight(frame)-PageVCSegmentIndicatorHeight, CGRectGetWidth(frame)-CGFloat(12), PageVCSegmentIndicatorHeight-CGFloat(8))
        }
        if segmentStyle == PageVCSegmentStyle.LineHighlight {
            indicatorView?.frame = CGRectMake(CGRectGetMinX(frame)+6, CGRectGetHeight(frame)-PageVCSegmentIndicatorHeight, CGRectGetWidth(frame)-12, PageVCSegmentIndicatorHeight-8)
        }
        contentScrollView.contentOffset = CGPointMake(0, 0)
        delegate?.pageVC(self, didChangeToIndex: 0, fromIndex: -1)
    }
    
    
    //刷新一个具体的栏目
    func reloadDataAtIndex(index:NSInteger) -> Void {
        
        var title = dataSource?.pageVC(self, titleAtIndex: index)
        if title == nil {
            title = ""
        }
        
        segmentTitles.replaceObjectAtIndex(index, withObject: title!)
        let label  : UILabel? = _segmentContainerView?.viewWithTag(1000+index) as? UILabel
        label?.text = title
        
        
        let oldVC = reusableVCDic[index]
        oldVC?.removeFromParentViewController()
        oldVC?.view.removeFromSuperview()
        
        
        let newVC = dataSource?.pageVC(self, viewControllerAtIndex: index)
        self.addChildViewController(newVC!)
        
        let contentBgView = _contentContainerView.viewWithTag(2000+index)
        contentBgView?.addSubview((newVC?.view)!)
        
        
        newVC?.view.snp_makeConstraints(closure: { (make) in
            make.edges.equalTo(contentBgView!)
        })
        
        reusableVCDic.setObject(newVC!, forKey: index)
        if currentIndex == index {
            delegate?.pageVC(self, didChangeToIndex: index, fromIndex: -1)
        }
        
    }
    
    //根据index获取对应的vc
    func viewControllerAtIndex(index:NSInteger) -> UIViewController? {
        if index >= numberOfContent {
            return nil
        }
        return reusableVCDic[index] as? UIViewController
    }
    
    
    func tapSegmentItemAction(gesture:UITapGestureRecognizer){
        
        let view = gesture.view
        let index = view!.tag - 1000
        
        delegate!.pageVC(self, didClickAtIndex: index)
        contentScrollView.setContentOffset(CGPointMake(CGFloat(index) * CGRectGetWidth(contentScrollView.frame), 0), animated: true)
    }
    
    /*
    *   MARK - ScrollView
    *
    */
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        
    }
    
    
    
    //其实是走的 ScrollView Delegate
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        
        let contentOffsetX = scrollView.contentOffset.x
        
        let index : NSInteger = NSInteger(floor((contentOffsetX - CGRectGetWidth(scrollView.frame)/2)/CGRectGetWidth(scrollView.frame)) + 1)
        
        self.transitionFromIndex(currentIndex, toIndex: index)
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let contentOffsetX = scrollView.contentOffset.x
        
        let index : NSInteger = NSInteger( floor((contentOffsetX - CGRectGetWidth(scrollView.frame) / 2) / CGRectGetWidth(scrollView.frame)) + 1);
        
        self.transitionFromIndex(currentIndex, toIndex: index)
        
    }
    
    
    
    
    func transitionFromIndex(fromIndex:NSInteger,toIndex:NSInteger){
        if fromIndex == toIndex {
            return
        }
        self.currentIndex = toIndex
    }
    
    /*
    *   mark - Button Action
    *
    */
    
    func editButtonAction(){
        _editMode = !_editMode
        if _editMode == true {
            delegate!.pageVC(self, didClickEditMode: PageVCEditMode.Default)
        }
        if _editMode == false {
            delegate!.pageVC(self, didClickEditMode: PageVCEditMode.Editing)
        }
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