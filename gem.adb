package body GEM is
    use C;

    procedure appl_exit is
    begin
	mt_appl_exit(aes_global);
    end appl_exit;

    procedure appl_write(appl_id : C.short; Message_Length : C.short; Message: access C.short) is
    begin
        mt_appl_write(appl_id, Message_Length, Message, aes_global);
    end appl_write;
    
    function graf_handle(w, h, cw, ch : access C.short) return C.short is
    begin
	return mt_graf_handle(w, h, cw, ch, aes_global);
    end graf_handle;

    procedure graf_mouse(Mouse_Number : Mouse_Form; MForm : System.Address) is
    begin
        mt_graf_mouse(Mouse_Form'Pos(Mouse_Number), System.Null_Address, aes_global);
    end graf_mouse;

    function wind_create(kind, x, y, w, h : C.short) return C.short is
    begin
	return mt_wind_create(kind, x, y, w, h, aes_global);
    end wind_create;

    procedure wind_open(wh, x, y, w, h : C.short) is
    begin
	mt_wind_open(wh, x, y, w, h, aes_global);
    end wind_open;

    procedure wind_close(wh : C.short) is
    begin
	mt_wind_close(wh, aes_global);
    end wind_close;

    procedure wind_delete(wh : C.short) is
    begin
	mt_wind_delete(wh, aes_global);
    end wind_delete;

    procedure wind_get(wh, mode : C.short; x, y, w, h : access C.short) is
    begin
	mt_wind_get(wh, mode, x, y, w, h, aes_global);
    end wind_get;
    
    procedure wind_set(wh, mode : C.short; x, y, w, h : C.short) is
    begin
        mt_wind_set(wh, mode, x, y, w, h, aes_global);
    end wind_set;

    procedure wind_set_str(wh, mode : C.short; str : C.Strings.chars_ptr) is
    begin
        mt_wind_set_str(wh, mode, str, aes_global);
    end wind_set_str;

    procedure wind_update(mode : C.short) is
    begin
	mt_wind_update(mode, aes_global);
    end wind_update;

    function evnt_multi(Typ, Clicks, Which_Button, Which_State,
		    Enter_Exit1, In_1x, In_1y, In_1w, In_1h : C.short;
		    Enter_Exit2, In_2x, In_2y, In_2w, In_2h : C.short;
		    Mesag_Buf : access Message_Array;
		    Interval : C.unsigned_long;
		    Out_X, Out_Y, Button_State, Key_State, Key, Return_Count : access C.short) return C.short is
    begin
	return mt_evnt_multi(Typ, Clicks, Which_Button, Which_State,
			 Enter_Exit1, In_1x, In_1y, In_1w, In_1h,
			 Enter_Exit2, In_2x, In_2y, In_2w, In_2h,
			 Mesag_Buf, Interval, Out_X, Out_Y,
			 Button_State, Key_State, Key, Return_Count, aes_global);
    end evnt_multi;
end GEM;
