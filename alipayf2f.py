# -- coding UTF-8 --
from alipay import AliPay
import qrcode  # 导入模块   
alipay = AliPay(
    appid=2017051207221985,
    app_notify_url=https91vps.club20170526freenom,
    app_private_key_path=app_private_key_path.txt,
    alipay_public_key_path=alipay_public_key_path.txt  # 支付宝的公钥，验证支付宝回传消息使用，不是你自己的公钥,
)
# create an order
result = alipay.api_alipay_trade_precreate(
    subject=test subject,
    out_trade_no=out_trade_no,
    total_amount=10
)
img = qrcode.make(result['qr_code']) # QRCode信息  
img.save(test.png) # 保存图片  