with Interfaces.C;
with System;

package GEM is
    package C renames Interfaces.C;

    type Short_Array is array (Positive range <>) of C.short;

    -- AES/VDI Types
    type GRECT is record
	g_x, g_y, g_w, g_h : C.short;
    end record;
    pragma Convention(C, GRECT);

    subtype AES_Id is C.short;

    aes_global : System.Address;
    pragma Import(C, aes_global, "aes_global");

    -- AES Functions
    function appl_init return C.short;
    pragma Import (C, appl_init, "appl_init");

    procedure mt_appl_exit(aes_global : System.Address);
    pragma Import (C, mt_appl_exit, "mt_appl_exit");
    procedure appl_exit;

    function  mt_graf_handle (w, h, cw, ch : access C.short; global_aes : System.Address) return C.short;
    pragma Import(C, mt_graf_handle, "mt_graf_handle");
    function graf_handle(w, h, cw, ch : access C.short) return C.short;

    function mt_wind_create (kind : C.short; x, y, w, h : C.short; aes_global : System.Address) return C.short;
    pragma Import(C, mt_wind_create, "mt_wind_create");
    function wind_create(kind : C.short; x, y, w, h : C.short) return C.short;

    procedure mt_wind_open (wh, x, y, w, h : C.short; aes_global : System.Address);
    pragma Import(C, mt_wind_open, "mt_wind_open");
    procedure wind_open(wh, x, y, w, h : C.short);

    procedure mt_wind_close (wh : C.short; aes_global : System.Address);
    pragma Import(C, mt_wind_close, "mt_wind_close");
    procedure wind_close(wh : C.short);

    procedure mt_wind_delete (wh : C.short; aes_global : System.Address);
    pragma Import(C, mt_wind_delete, "mt_wind_delete");
    procedure wind_delete(wh : C.short);

    procedure mt_wind_get (wh, mode : C.short; x, y, w, h : access C.short; aes_global : System.Address);
    pragma Import(C, mt_wind_get, "mt_wind_get");
    procedure wind_get(wh, mode : C.short; x, y, w, h : access C.short);

    procedure mt_wind_update(mode : C.short; aes_global : System.Address);
    pragma Import(C, mt_wind_update, "mt_wind_update");
    procedure wind_update(mode : C.short);

    -- VDI Functions
    type Work_Array is array (0 .. 10) of C.short;
    type Int57_Array is array (0 .. 56) of C.short;

    procedure v_opnvwk (work_in : Work_Array; handle : access C.short; work_out : Int57_Array);
    pragma Import(C, v_opnvwk, "v_opnvwk");

    procedure v_clsvwk (handle : C.short);
    pragma Import(C, v_clsvwk, "v_clsvwk");

    procedure v_pline (handle : C.short; count : C.short; points : access C.short);
    pragma Import(C, v_pline, "v_pline");

    procedure vs_clip (handle, on : C.short; rect : access C.short);
    pragma Import(C, vs_clip, "vs_clip");

    procedure vr_recfl (handle : C.short; rect : access C.short);
    pragma Import(C, vr_recfl, "vr_recfl");

    procedure vsf_interior (handle, style : C.short);
    pragma Import(C, vsf_interior, "vsf_interior");

    procedure vsf_color (handle, color : C.short);
    pragma Import(C, vsf_color, "vsf_color");

    procedure vsl_color (handle, color : C.short);
    pragma Import(C, vsl_color, "vsl_color");

    -- Event
    type Message_Array is array (0 .. 7) of C.short;

    function mt_evnt_multi(Typ, Clicks, Which_Button, Which_State : C.short;
		       Enter_Exit1, In_1X, In_1y, In_1w, In_1h : C.short;
		       Enter_exit2, In_2X, In_2y, In_2w, In_2h : C.short;
		       Mesag_Buf : access Message_Array;
		       Interval : C.unsigned_long;
		       Out_X, Out_Y, Button_State, Key_State, Key, Return_Count : access C.short;
		       global_aes : System.Address) return C.short;
    pragma Import(C, mt_evnt_multi, "mt_evnt_multi");
    function evnt_multi(Typ, Clicks, Which_Button, Which_State : C.short;
			Enter_Exit1, In_1x, In_1y, In_1w, In_1h : C.short;
			Enter_Exit2, In_2x, In_2y, In_2w, In_2h : C.short;
			Mesag_Buf : access Message_Array;
			Interval : C.unsigned_long;
			Out_X, Out_Y, Button_State, Key_State, Key, Return_Count : access C.short) return C.short;

    -- Constants
    WM_REDRAW  : constant := 20;
    WM_CLOSED  : constant := 21;
    NAME       : constant := 1;
    CLOSER     : constant := 2;
    MOVER      : constant := 4;
    FULLER     : constant := 8;

    FIS_SOLID  : constant := 1;

    MU_KEYBD            : constant C.short := 16#0001#;
    MU_BUTTON           : constant C.short := 16#0002#;
    MU_M1               : constant C.short := 16#0004#;
    MU_M2               : constant C.short := 16#0008#;
    MU_MESAG            : constant C.short := 16#0010#;
    MU_TIMER            : constant C.short := 16#0020#;
    MU_WHEEL            : constant C.short := 16#0040#;
    MU_MX               : constant C.short := 16#0080#;
    MU_NORM_KEYBD       : constant C.short := 16#0100#;
    MU_DYNAMIC_KEYBD    : constant C.short := 16#0200#;
    X_MU_DIALOG         : constant C.short := 16#0400#;

    WF_WORKXYWH		: constant C.short := 4;
    WF_FULLXYWH		: constant C.short := 7;
    WF_FIRSTXYWH	: constant C.short := 11;
    WF_NEXTXYWH		: constant C.short := 12;

end GEM;
