        {% if theme.wechat.qrcode %}
          <div class="qrcode-section" itemprop="qrcod3">
<img class="qrcode" itemprop="image"
	style="padding-top:20px;width:80%;"	
               src="{{ url_for( theme.wechat.qrcode) }}"
               alt="{{ theme.author }}" />
          </div>
        {% endif %}


