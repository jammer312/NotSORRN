interface IAbility
{
    string getTextureName();
    CBlob@ getBlob();
    void activate();
    void onTick();
    void onRender(CSprite@ sprite);
    void onCommand(CBlob@ blob, u8 cmd, CBitStream @params);
    string getBorder();
}

class CAbilityBase : IAbility
{
    void onTick(){}
    string getBorder(){return border;}
    string textureName;
    string border = "Border.png";
    CBlob@ blob;

    string getTextureName() {return textureName;}
    CBlob@ getBlob() {return blob;}


    CAbilityBase(string _textureName, CBlob@ _blob)
    {
        textureName = _textureName;
        @blob = _blob;
    }

    void activate()
    {
        print("Base ability activated for some reason on blob " + blob.getConfig());
    }

    void onRender(CSprite@ sprite){}

    void onCommand(CBlob@ blob, u8 cmd, CBitStream @params ){}
}

class CAbilityEmpty : CAbilityBase
{
	string getTextureName() override
	{
		return "abilityEmpty.png";
	}
	void activate() override
	{
		//I know this part may be hard to under stand, a lot is going on here but I think you can work through it if you try
	}
}

class CToggleableAbillityBase : CAbilityBase
{
    CToggleableAbillityBase()
    {
        border = "BorderRed.png";
    }
    bool activated = false;
    void activate() override
    {
        activated = !activated;

        border = activated ? "BorderGreen" : "BorderRed";
    }
}

class CAbilityManager
{
    IAbility@[] abilities;
	IAbility@[] abilityBar;
    uint selected = 0;
    CBlob@ blob;
	bool menuOpen = false;

    IAbility@ getSelected() {return abilityBar[selected];}

    void onInit(CBlob@ blob)
    {	
		CAbilityEmpty abilityEmpty;
		for(int i = 0; i < 5; i++)
		{
			abilityBar.push_back(abilityEmpty);
		}
		abilities.push_back(abilityEmpty);
        CPoint abilityPoint(blob,"abilityPoint.png");
        abilities.push_back(abilityPoint);
		

        @this.blob = blob;
        blob.addCommandID("ActivateAbilityIndex");
    }

    void sendActivateAbilityIndexCommand(int i)
    {
        CBitStream params;
        params.write_s32(i);
        this.blob.SendCommand(this.blob.getCommandID("ActivateAbilityIndex"),params);
    }
    
    void onCommand( CBlob@ blob, u8 cmd, CBitStream @params )
    {
        if(cmd == blob.getCommandID("ActivateAbilityIndex"))
        {
            activateAbilityIndex(params.read_s32());
        }
        else
        {
            for(int i = 0; i < abilities.length(); i++)
            {
                abilities[i].onCommand(blob,cmd,params);
            }
        }
    }

    void activateAbilityIndex(int i)
    {
        if(i > abilityBar.length())
        {
            error("Attempted to run ability out of index");
            return;
        }

        abilityBar[i].activate();
    }

	int holdingIndex;

    void onTick(CBlob@ blob)
    {
        for(int i = 0; i < abilities.length(); i++)
        {
            abilities[i].onTick();
        }
        
        if(isMe(blob))
        {
			if(getControls().isKeyJustPressed(KEY_KEY_I))
			{
				start = getControls().getMouseScreenPos();
				menuOpen = !menuOpen;
			}
            if(getControls().isKeyJustPressed(KEY_KEY_B))
            {
                sendActivateAbilityIndexCommand(selected);
            }

            if(getControls().isKeyJustPressed(KEY_LBUTTON))
            {
                Vec2f mpos = getControls().getMouseScreenPos();
				
				int newselection = getAbilityIndexHovered(mpos);
                selected = newselection > -1 ? newselection : selected;

				if(menuOpen)
				{
					holdingIndex = getAbilityMenuIndexHovered(mpos);
				}

            }

			if(!getControls().isKeyPressed(KEY_LBUTTON))
			{
				if(holdingIndex > -1)
				{
					int abilityBarIndex = getAbilityIndexHovered(getControls().getMouseScreenPos());
					if(abilityBarIndex > -1)
					{
						@abilityBar[abilityBarIndex] = abilities[holdingIndex];
					}
				}
				holdingIndex = -1;
			}
        }
    }

    Vec2f getAbilityPos(int index)
    {
        return Vec2f(4 + 4*index + 32 * index, 4);
    }

    int getAbilityIndexHovered(Vec2f pos)
    {
		int index = -1;
        if(pos.y <= 40 && pos.y >= 4)
        {
            for(int i = 0; i < abilityBar.length(); i++)
            {
                int x = (4 + 4*i + 32 * i);
                if(pos.x >= x && pos.x <= x + 32)
                {
                    index = i;
                    break;
                }
            }
        }
		return index;
    }

	int getAbilityMenuIndexHovered(Vec2f pos)
	{
		int index = -1;

		for(int i = 0; i < abilities.length(); i++)
		{
			Vec2f abilityPos = Vec2f(i%numColumns * 36, i / numColumns * 36) + start + Vec2f(4,4);

			if(pos.x >= abilityPos.x && pos.x <= abilityPos.x + 32 && pos.y >= abilityPos.y && pos.y <= abilityPos.y + 32)
			{
				index = i;
				break;
			}
		}

		return index;
	}

	u32 numColumns = 4;

	Vec2f start;
	Vec2f end;
	int getRowCount()
	{
		int rowCount;
		float fNumColumns = numColumns;
		float rowsUneven = (abilities.length() / fNumColumns );
		rowCount = Maths::Ceil(rowsUneven);
		return rowCount;
	}
    void onRender(CSprite@ this)
    {
        for(int i = 0; i < abilities.length(); i++)
        {
            abilities[i].onRender(this);
        }

        if(!isMe(blob)) {return;}
        for(int i = 0; i < abilityBar.length(); i++)//draw toolbar abilities
        {
            GUI::DrawIcon(abilityBar[i].getTextureName(), 0, Vec2f(16,16), getAbilityPos(i), 1);
			int hovered = getAbilityIndexHovered(getControls().getMouseScreenPos());
			if(hovered > -1)
			{
				GUI::DrawIcon(abilityBar[hovered].getBorder(),0,Vec2f(18,18), Vec2f(2 + 4*hovered + 32 * hovered,2),1,SColor(127,127,127,127));
			}
        }
        GUI::DrawIcon(getSelected().getBorder(),0,Vec2f(18,18), Vec2f(2 + 4*selected + 32 * selected,2),1);// draw toolbar selected

        GUI::DrawText("Activate: {B}\nManage: {I}", Vec2f(16,40), SColor(255,127,127,127));

		if(menuOpen)//menu rendering
		{
			end = Vec2f(start.x + numColumns * 4 + numColumns * 32 +4,start.y + getRowCount() * 36 + 4);

			GUI::DrawRectangle(start,end);

			for(int i = 0; i < abilities.length; i++)
			{
				Vec2f iconPos = Vec2f(i%numColumns * 36, i / numColumns * 36) + start + Vec2f(4,4);
				if(holdingIndex > -1 && holdingIndex == i)
				{
					GUI::DrawIcon(abilities[i].getTextureName(), 0, Vec2f(16,16), iconPos, 1,SColor(127,60,60,60));
				}
				else
				{
					GUI::DrawIcon(abilities[i].getTextureName(), 0, Vec2f(16,16), iconPos, 1);
				}
			}

			int hovered = holdingIndex > -1 ? holdingIndex : getAbilityMenuIndexHovered(getControls().getMouseScreenPos());
			if(hovered > -1)
			{
				GUI::DrawIcon(getSelected().getBorder(),0,Vec2f(18,18), start + Vec2f(2,2) + Vec2f(hovered%numColumns * 36, hovered/numColumns * 36),1);
			}
		}

		if(holdingIndex > -1)
		{
			GUI::DrawIcon(abilities[holdingIndex].getTextureName(),0,Vec2f(16,16),getControls().getMouseScreenPos() - Vec2f(16,16),1);
		}
    }
}

bool isMe(CBlob@ blob)
{
    return blob.getPlayer() !is null && blob.getPlayer() is getLocalPlayer();
}

class CPoint : CAbilityBase
{
    CPoint(CBlob@ blob, string textureName)
    {
        super(textureName,blob);

        blob.addCommandID("CPoint_timeSync");
        blob.addCommandID("CPoint_tposSync");
    }

    u32 _time = 0;
    u32 time
    {
        get{return _time;}
        set{CBitStream params; params.write_u32(value); blob.SendCommand(blob.getCommandID("CPoint_timeSync"),params);}
    }
    Vec2f _tpos;
    Vec2f tpos 
    {
        get{return _tpos;}
        set{CBitStream params; params.write_Vec2f(value); blob.SendCommand(blob.getCommandID("CPoint_tposSync"),params);}
    }

    void activate() override
    {
        time = getGameTime() + 30*5;

        CPlayer@ p = blob.getPlayer();
        if(p !is null && p.isMyPlayer())
        {
            tpos = getControls().getMouseWorldPos();
        }
    }

    void onRender(CSprite@ sprite) override
    {
        if(time > getGameTime())
        {
            GUI::DrawSplineArrow(sprite.getBlob().getPosition(), tpos, SColor(255,255,127,127));
        }
    }

    void onCommand(CBlob@ blob, u8 cmd, CBitStream@ params)
    {
        if(cmd == blob.getCommandID("CPoint_timeSync")){ _time = params.read_u32();}
        else if(cmd == blob.getCommandID("CPoint_tposSync")){ _tpos = params.read_Vec2f();}
    }
}