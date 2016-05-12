//
//  HomeViewController.swift
//  NavPageVCDemo
//
//  Created by langyue on 16/5/11.
//  Copyright © 2016年 langyue. All rights reserved.
//

import UIKit

class HomeViewController: PageVC,PageVCDataSource,PageVCDelegate {

    
    var modeArr = []
    var vcArr : NSMutableArray = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.navigationItem.title = "News"
        self.view.backgroundColor = UIColor.whiteColor()
        self.modeArr = ["首页阿","音频视频阿","纵览","德玛西亚皇子","报纸书本","游戏","邮箱"]
        
        
        for idx in 0...modeArr.count-1 {
            
            let vc = UIViewController()
            vc.view.backgroundColor = UIColor.init(red: CGFloat(arc4random()%255)/255.0, green: CGFloat(arc4random()%255)/255.0, blue: CGFloat(arc4random()%255)/255.0, alpha: 1.0)
            
            
            let viewbg = UILabel()
            vc.view.addSubview(viewbg)
            viewbg.text = "==== \(idx)"
            viewbg.snp_makeConstraints(closure: { (make) in
                make.centerX.equalTo(vc.view.snp_centerX)
                make.centerY.equalTo(vc.view.snp_centerY)
                make.width.height.equalTo(80)
            })
            viewbg.textColor = UIColor.blueColor()
            viewbg.backgroundColor = UIColor.blackColor()
            
            
            
            vcArr.addObject(vc)
        }
        
        
        
        
        
        
        
        self.delegate = self
        self.dataSource = self
        
        //self.segmentStyle = PageVCSegmentStyle.Default
        self.segmentStyle = PageVCSegmentStyle.LineHighlight
        
        
        self.normalTextColor = UIColor.blackColor()
        self.highightTextColor = UIColor.redColor()
        self.lineBackground = UIColor.orangeColor()
        
        self.reloadData()
        
        // Do any additional setup after loading the view.
    }

    
    
    
    //设置点击pageVCIndex的vc
    func pageVC(pageVC: PageVC?, viewControllerAtIndex index: NSInteger?) -> UIViewController {
        return vcArr[index!] as! UIViewController
    }
    //设置点击pageVCIndex的title
    func pageVC(pageVC: PageVC?, titleAtIndex index: NSInteger?) -> String {
        return self.modeArr[index!] as! String
    }
    
   
    //设置栏目的个数
    func numberOfContentForPageVC(pageVC: PageVC?) -> NSInteger? {
        return self.modeArr.count
        
    }
    
    
    
    
    //不一定需要实现以下方法
    
    func pageVC(pageVC:PageVC?,willChangeToIndex toIndex:NSInteger?,fromIndex:NSInteger?){
        
        
        
    }
    
    
    
    //已经改变到index
    func pageVC(pageVC:PageVC?,didChangeToIndex toIndex:NSInteger?,fromIndex:NSInteger?){
        print("PageVC - index \(toIndex) - fromIndex \(fromIndex)")
    }
    //在index处已点击 此方法暂时不适用
    func pageVC(pageVC:PageVC?,didClickAtIndex index:NSInteger?){
        
        
        
    }
    //点击Edit按钮的mode
    func pageVC(pageVC:PageVC?,didClickEditMode mode:PageVCEditMode){
        
          let alert = UIAlertController(title: "+/-",message: "添加或者删除栏目",preferredStyle: .Alert)
          let action = UIAlertAction(title: "I know",style: .Default,handler: { (action:UIAlertAction) in
              print("action block")
          })
          alert.addAction(action)
          self.presentViewController(alert, animated: true, completion: nil)
        
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
