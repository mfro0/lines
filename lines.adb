with Ada.Unchecked_Conversion;
with Interfaces.C; use Interfaces.C;
with System;
with Ada.Calendar;

procedure Lines is
    package C renames Interfaces.C;

    type Int_Array is array (Positive range <>) of C.int;

    -- AES/VDI Types
    type GRECT is record
	g_x, g_y, g_w, g_h : C.int;
    end record;
    pragma Convention (C, GRECT);

    subtype AES_Id is C.int;

    aes_global : System.Address;
    pragma Import(C, aes_global, "aes_global");

    -- AES Functions
    function appl_init return C.int;
    pragma Import (C, appl_init, "mt_appl_init");

    procedure appl_exit;
    pragma Import (C, appl_exit, "mt_appl_exit");

    function  mt_graf_handle (w, h, cw, ch : access C.int; global_aes : System.Address) return C.int;
    pragma Import (C, mt_graf_handle, "mt_graf_handle");
    function graf_handle(w, h, cw, ch : access C.int) return C.int is
    begin
	return mt_graf_handle(w, h, cw, ch, aes_global);
    end graf_handle;

    function wind_create (kind : C.int; x, y, w, h : C.int) return C.int;
    pragma Import (C, wind_create, "mt_wind_create");

    procedure wind_open (wh, x, y, w, h : C.int);
    pragma Import (C, wind_open, "mt_wind_open");

    procedure wind_close (wh : C.int);
    pragma Import (C, wind_close, "mt_wind_close");

    procedure wind_delete (wh : C.int);
    pragma Import (C, wind_delete, "mt_wind_delete");

    procedure wind_get (wh, mode : C.int; x, y, w, h : access C.int);
    pragma Import (C, wind_get, "mt_wind_get");

    procedure wind_update (mode : C.int);
    pragma Import (C, wind_update, "mt_wind_update");

    -- VDI Functions
    type Work_Array is array (0 .. 10) of C.int;
    type Int57_Array is array (0 .. 56) of C.int;

    procedure v_opnvwk (work_in : Work_Array; handle : access C.int; work_out : Int57_Array);
    pragma Import (C, v_opnvwk, "v_opnvwk");

    procedure v_clsvwk (handle : C.int);
    pragma Import (C, v_clsvwk, "v_clsvwk");

    procedure v_pline (handle : C.int; count : C.int; points : access C.short);
    pragma Import (C, v_pline, "v_pline");

    procedure vs_clip (handle, on : C.int; rect : access C.short);
    pragma Import (C, vs_clip, "vs_clip");

    procedure vr_recfl (handle : C.int; rect : access C.short);
    pragma Import (C, vr_recfl, "vr_recfl");

    procedure vsf_interior (handle, style : C.int);
    pragma Import (C, vsf_interior, "vsf_interior");

    procedure vsf_color (handle, color : C.int);
    pragma Import (C, vsf_color, "vsf_color");

    procedure vsl_color (handle, color : C.int);
    pragma Import (C, vsl_color, "vsl_color");

    -- Event
    type Message_Array is array (0 .. 7) of C.int;

    function evnt_multi
	(Flags       : C.int;
	 Clicks      : C.int;
	 Mask        : C.int;
	 State       : C.int;
	 Msg         : access Message_Array;
	 Rect1_X     : C.int;
	 Rect1_Y     : C.int;
	 Rect1_W     : C.int;
	 Rect1_H     : C.int;
	 Interval    : C.int;
	 MX, MY      : access C.int) return C.int;
    pragma Import (C, evnt_multi, "mt_evnt_multi");

    -- Constants
    WM_REDRAW  : constant := 20;
    WM_CLOSED  : constant := 21;
    NAME       : constant := 1;
    CLOSER     : constant := 2;
    MOVER      : constant := 4;
    FULLER     : constant := 8;

    FIS_SOLID  : constant := 1;

    -- Data
    type Point is record
      X, Y : C.int;
    end record;

    Max_Trail : constant := 5;
    Trail     : array (1 .. Max_Trail) of Point := (others => (X => -1, Y => -1));

    Colors    : constant array (1 .. Max_Trail) of C.int := (16#F800#, 16#C000#, 16#9000#, 16#6000#, 16#3000#);

    -- Handles
    Vdi_Handle : aliased C.int;
    Win        : C.int;
    Work_Area  : GRECT;

    procedure Update_Trail (NX, NY : C.int) is
    begin
	for I in reverse Trail'First + 1 .. Trail'Last loop
	    Trail(I) := Trail(I - 1);
	end loop;
	Trail(1).X := NX;
	Trail(1).Y := NY;
    end Update_Trail;

    procedure Draw_Trail is
	Points : array (1 .. 4) of aliased C.short;
    begin
	for I in Trail'First .. Trail'Last - 1 loop
	    if Trail(I + 1).X >= 0 then
		vsl_color (Vdi_Handle, 1);
		Points(1) := C.short (Trail(I).X);
		Points(2) := C.short (Trail(I).Y);
		Points(3) := C.short (Trail(I + 1).X);
		Points(4) := C.short (Trail(I + 1).Y);
		v_pline (Vdi_Handle, 2, Points (Points'First)'Access);
	    end if;
	end loop;
    end Draw_Trail;

    procedure Redraw_Window is
	R : array (1 .. 4) of aliased C.short;
    begin
	R(1) := C.short (Work_Area.g_x);
	R(2) := C.short (Work_Area.g_y);
	R(3) := C.short (Work_Area.g_x + Work_Area.g_w - 1);
	R(4) := C.short (Work_Area.g_y + Work_Area.g_h - 1);
	vs_clip (Vdi_Handle, 1, R(R'First)'Access);
	vsf_interior (Vdi_Handle, FIS_SOLID);
	vsf_color (Vdi_Handle, 0);
	vr_recfl (Vdi_Handle, R(R'First)'Access);
	Draw_Trail;
	vs_clip (Vdi_Handle, 0, R(R'First)'Access);
    end Redraw_Window;

    app_id  : C.int;
begin
    app_id := appl_init;

    declare
	Work_In  : Work_Array := (others => 1);
	Work_Out : Int57_Array;
	Dummy    : aliased C.int := 0;
    begin
	Vdi_Handle := graf_handle (Dummy'Access, Dummy'Access, Dummy'Access, Dummy'Access);
	v_opnvwk (Work_In, Vdi_Handle'Access, Work_Out);
    end;

    Win := wind_create (NAME + CLOSER + MOVER + FULLER, 50, 50, 320, 200);
    wind_open (Win, 50, 50, 320, 200);

    declare
	X, Y, W, H : aliased C.int;
    begin
	wind_get (Win, 4, X'Access, Y'Access, W'Access, H'Access);
	Work_Area.g_x := X;
	Work_Area.g_y := Y;
	Work_Area.g_w := W;
	Work_Area.g_h := H;
    end;

    -- Main loop
    declare
	Msg : aliased Message_Array;
	Quit : Boolean := False;
	MX, MY : aliased C.int := 0;
	Dummy	: C.int;
    begin
	loop
	    -- Random point inside work area
	    Update_Trail (Work_Area.g_x + C.int (Integer (Work_Area.g_w) * Integer (Ada.Calendar.Seconds (Ada.Calendar.Clock)) mod Integer(Work_Area.g_w)),
			  Work_Area.g_y + C.int (Integer (Work_Area.g_h) * Integer (Ada.Calendar.Seconds (Ada.Calendar.Clock)) mod Integer(Work_Area.g_h)));

	    Dummy := evnt_multi (16#11#, 1, 1, 1, Msg'Access,
				 0, 0, 0, 0, 200, MX'Access, MY'Access);
	    begin
		if Msg(0) = WM_REDRAW then
		    wind_update (1);
		    Redraw_Window;
		    wind_update (0);
		elsif Msg(0) = WM_CLOSED then
		    Quit := True;
		end if;
	    end;

	    Redraw_Window;
	    exit when Quit;
	end loop;
    end;

    wind_close (Win);
    wind_delete (Win);
    v_clsvwk (Vdi_Handle);
    appl_exit;
end Lines;
